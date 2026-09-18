package it.mdc.tool.prototyping;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/** Versioned, dependency-free description of the stream wrapper and KV260 plan.
 * Step 3 emits Tcl from this plan; it does not assert a successful hardware build.
 * Java 8 compatible; no Eclipse, ORCC or JSON-library dependency.
 */
public final class CoprocessorSpec {
    public static final int STREAM_WORD_BITS = 32;
    public static final int LEGACY_OUTPUT_COUNTER_BITS = 8;
    public static final int OUTPUT_COUNTER_BITS = 32;
    public static final long CONTROL_BASE = 0xA0010000L;
    public static final long REGISTER_RANGE = 0x10000L;

    public static final class PortSpec {
        public final String name, direction;
        public final int index, tokenBits, wrapperBits;
        public final boolean signed;
        public PortSpec(String name, String direction, int index, int tokenBits,
                        int wrapperBits, boolean signed) {
            this.name = name; this.direction = direction; this.index = index;
            this.tokenBits = tokenBits; this.wrapperBits = wrapperBits; this.signed = signed;
        }
        public String id() { return direction + ":" + index; }
        public String axis() {
            return (direction.equals("input") ? "s" : "m") +
                (index < 10 ? "0" : "") + index + "_axis";
        }
    }
    public static final class ModeSpec {
        public final int id;
        public final String name;
        // Null means unknown, never an assumption that all ports are active.
        public final List<String> activePortIds;
        public final String membershipSource;
        public ModeSpec(int id, String name, List<String> activePortIds, String source) {
            this.id = id; this.name = name;
            this.activePortIds = activePortIds == null ? null : new ArrayList<>(activePortIds);
            this.membershipSource = source;
        }
    }
    private final String network, part, board;
    private final boolean hasSwitches;
    private final List<PortSpec> ports;
    private final List<ModeSpec> modes;
    private final List<String> warnings;

    public CoprocessorSpec(String network, String part, String board, boolean hasSwitches,
                           List<PortSpec> ports, List<ModeSpec> modes, List<String> warnings) {
        this.network = network; this.part = part; this.board = board;
        this.hasSwitches = hasSwitches;
        this.ports = new ArrayList<>(ports); this.modes = new ArrayList<>(modes);
        this.warnings = new ArrayList<>(warnings);
        Collections.sort(this.ports, Comparator.comparingInt((PortSpec p) ->
            p.direction.equals("input") ? 0 : 1).thenComparingInt(p -> p.index));
        Collections.sort(this.modes, Comparator.comparingInt(m -> m.id));
        validate();
    }
    private static void require(boolean ok, String error) {
        if (!ok) throw new IllegalArgumentException("accelerator.json: " + error);
    }
    private void validate() {
        require(network != null && !network.isEmpty(), "missing network name");
        require(part != null && part.startsWith("xck26"), "profile requires a K26 part");
        require(board != null && board.contains(":kv260_som:"), "KV260 generator requires a kv260_som board part");
        Set<String> ids = new HashSet<>(), names = new HashSet<>();
        int in = 0, out = 0;
        for (PortSpec p : ports) {
            require(p.direction.equals("input") || p.direction.equals("output"), "invalid port direction");
            require(p.index == (p.direction.equals("input") ? in++ : out++), "port indices must be contiguous from zero");
            require(p.name != null && !p.name.isEmpty(), "missing port name");
            require(ids.add(p.id()) && names.add(p.name), "duplicate port ID/name");
           require(p.tokenBits > 0 && p.tokenBits <= STREAM_WORD_BITS, "unsupported token width");
            require(p.wrapperBits == p.tokenBits, "protocol data width differs from token width");
        }
        require(in > 0 && out > 0, "at least one input and one output are required");
        require(ports.size() <= 15, "initial KV260 plan supports at most 15 DMA controllers (16 control interconnect outputs including accelerator)");
        Set<Integer> modeIds = new HashSet<>(); Set<String> modeNames = new HashSet<>();
        for (ModeSpec m : modes) {
            require(m.id >= 1 && m.id <= 255 && modeIds.add(m.id), "invalid/duplicate 8-bit configuration ID");
            require(m.name != null && !m.name.isEmpty() && modeNames.add(m.name), "missing/duplicate mode name");
            require(m.membershipSource != null, "missing membership provenance");
            if (m.activePortIds != null) {
                Set<String> active = new HashSet<>(m.activePortIds);
                require(active.size() == m.activePortIds.size() && ids.containsAll(active), "invalid/duplicate mode port reference");
            }
        }
       // An empty list can occur when premerged XDF recovery lost mode identities.
       // Preserve that fact and block deployment instead of inventing mode IDs.
    }
    public static long dmaBase(int index) {
        return 0xA0000000L + (index < 2 ? index : index + 1L) * 0x100000L;
    }
    private static String hex(long value) { return String.format(java.util.Locale.ROOT, "0x%08X", value); }
    private static Map<String,Object> object(Object... kv) {
        Map<String,Object> result = new LinkedHashMap<>();
        for (int i=0; i<kv.length; i+=2) result.put((String)kv[i], kv[i+1]);
        return result;
    }
    public Map<String,Object> toDocument() {
        List<Object> portRows = new ArrayList<>(), modeRows = new ArrayList<>(), dmaRows = new ArrayList<>();
        List<Object> registers = new ArrayList<>();
        registers.add(object("name", "control", "offset_bytes", 0, "width_bits", 32,
            "mode_id_lsb", 24, "mode_id_width", 8, "counter_clear_bit", 2, "start_bit", 0));
        Set<String> unresolved = new HashSet<>();
        boolean membershipKnown = !modes.isEmpty();
        for (PortSpec p : ports) {
            portRows.add(object("id", p.id(), "name", p.name, "direction", p.direction,
                "index", p.index, "token_bits", p.tokenBits, "token_signed", p.signed,
                "wrapper_data_bits", p.wrapperBits, "axis_interface", p.axis(),
                "transport_bits", STREAM_WORD_BITS, "bytes_per_token", STREAM_WORD_BITS/8,
                "packing", "one_token_per_word_low_bits", "semantic_role", null));
            int controller = dmaRows.size();
            dmaRows.add(object("controller", "axi_dma_" + controller, "channel_id", controller,
                "port_id", p.id(), "direction", p.direction.equals("input") ? "MM2S" : "S2MM",
                "base_address", hex(dmaBase(controller)), "range_bytes", REGISTER_RANGE,
                "scatter_gather", false));
            if (p.direction.equals("output")) {
                registers.add(object("name", "output_count_" + p.index, "port_id", p.id(),
                    "offset_bytes", 4*(p.index+1), "width_bits", 32, "units", "accepted_axis_beats",
                    "counter_bits", OUTPUT_COUNTER_BITS,
                    "max_packet_beats", (1L<<OUTPUT_COUNTER_BITS)-2,
                    "tlast_disabled_value", (1L<<OUTPUT_COUNTER_BITS)-1));
            }
        }
        for (ModeSpec m : modes) {
            membershipKnown &= m.activePortIds != null;
            List<String> active = null;
            if (m.activePortIds != null) {
                active = new ArrayList<>();
                for (PortSpec p : ports) if (m.activePortIds.contains(p.id())) active.add(p.id());
            } else unresolved.add(m.name);
            modeRows.add(object("id", m.id, "name", m.name, "selector_used", hasSwitches,
                "active_port_ids", active, "membership_source", m.membershipSource));
        }
        List<String> notes = new ArrayList<>(warnings);
        if (modes.isEmpty()) notes.add("Configuration identities unavailable; do not infer modes from a merged network name.");
        for (ModeSpec m : modes) if (unresolved.contains(m.name))
            notes.add("Per-mode port membership unavailable: " + m.name);
        notes.add("Output counter is 32 bits; DMA buffer capacity and configured DMA length width impose separate, smaller limits.");
        Map<String,Object> doc = object("schema_version", 2,
            "generation_stage", "tcl_scripts_emitted", "deployment_ready", false,
            "network", network,
            "target", object("profile", "kv260-linux-stream32-v2", "part", part, "board_part", board,
                "processor", "ARM", "coupling", "STREAM", "intended_runtime", "linux-uniss-dma"),
            "ports", portRows, "modes", modeRows,
            "metadata_status", object("mode_ids_available", !modes.isEmpty(),
                "mode_port_membership_complete", membershipKnown, "application_roles_complete", false),
            "wrapper_registers", registers,
            "hardware_plan", object("status", "scripts_emitted_not_built", "dma_topology", "one_controller_per_port",
                "control_base_address", hex(CONTROL_BASE), "control_range_bytes", REGISTER_RANGE,
                "memory_ps_interface", "S_AXI_HPC0_FPD", "dma_controllers", dmaRows,
                "vivado_version", "2024.2", "dma_address_bits", 32, "dma_length_bits", 23,
                "control_address_bits", 16, "clock_mhz", 100,
                "ddr_low_base", "0x00000000", "ddr_low_range", "0x80000000"),
                "linux_driver", object("abi_version", 1, "device", "/dev/mdc_accel0",
            	"buffer_bytes_per_channel", 65536, "dma_mask_bits", 32, "completion", "polling",
            	"legacy_uniss_abi_compatible", false, "deployment_verified", false),            
            "integration", object("kv260_tcl_consumes_shared_spec", true, "legacy_driver_consumes_manifest", false,
            		"kernel_uapi_version", 1, "linux_driver_consumes_shared_spec", true,
            		"linux_generation_stage", "sources_emitted"), "warnings", notes);
        return doc;
    }
        public String toJson() {
                StringBuilder out = new StringBuilder(); json(toDocument(), out, 0); out.append('\n'); return out.toString();        
    }
    private static void indent(StringBuilder out, int depth) { for(int i=0;i<depth*2;i++) out.append(' '); }
    private static void quote(String text, StringBuilder out) {
        out.append('"');
        for(int i=0;i<text.length();i++) {
            char c=text.charAt(i);
            switch(c) {
            case '"': out.append("\\\""); break;
            case '\\': out.append("\\\\"); break;
            case '\n': out.append("\\n"); break;
            case '\r': out.append("\\r"); break;
            case '\t': out.append("\\t"); break;
            default: if(c < 32) out.append(String.format(java.util.Locale.ROOT,"\\u%04x",(int)c)); else out.append(c);
            }
        }
        out.append('"');
    }
    private static void json(Object v, StringBuilder out, int depth) {
        if(v == null) { out.append("null"); return; }
        if(v instanceof String) { quote((String)v,out); return; }
        if(v instanceof Boolean || v instanceof Number) { out.append(v); return; }
        if(v instanceof Map) {
            out.append("{\n"); boolean first=true;
            for(Object raw : ((Map<?,?>)v).entrySet()) {
                Map.Entry<?,?> e=(Map.Entry<?,?>)raw;
                if(!first) out.append(",\n"); first=false;
                indent(out,depth+1); quote((String)e.getKey(),out); out.append(": "); json(e.getValue(),out,depth+1);
            }
            out.append('\n'); indent(out,depth); out.append('}'); return;
        }
        if(v instanceof List) {
            out.append('['); boolean first=true;
            for(Object entry : (List<?>)v) {
                if(!first) out.append(','); first=false;
                out.append('\n'); indent(out,depth+1); json(entry,out,depth+1);
            }
            if(!first) {out.append('\n'); indent(out,depth);} out.append(']'); return;
        }
        throw new IllegalArgumentException("Unsupported JSON value");
    }
}