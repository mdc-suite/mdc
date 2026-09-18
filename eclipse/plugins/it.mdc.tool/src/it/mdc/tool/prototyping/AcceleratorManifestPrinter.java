package it.mdc.tool.prototyping;

import it.mdc.tool.core.ConfigManager;
import it.mdc.tool.core.platformComposer.ProtocolManager;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.AtomicMoveNotSupportedException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;
import net.sf.orcc.df.Network;
import net.sf.orcc.df.Port;
import net.sf.orcc.util.OrccLogger;

/** ORCC adapter. Reads final wrapper maps and existing configuration IDs;
 * it never assigns a new configuration ID or invents per-mode membership.
 */
public final class AcceleratorManifestPrinter {
    private AcceleratorManifestPrinter() {}

    public static boolean supports(String part, String processor, String coupling, Boolean dma) {
        return part != null && part.startsWith("xck26") && "ARM".equals(processor)
            && "s".equals(coupling) && Boolean.TRUE.equals(dma);
    }

    public static void write(Path outputRoot, Network network, String part, String board,
            Map<Port,Integer> inputs, Map<Port,Integer> outputs,
            Map<String,Map<String,String>> vertexMaps, ConfigManager configs,
            ProtocolManager protocol, boolean hasSwitches) throws IOException {
        Path destination = outputRoot.resolve("accelerator.json");
        // Remove an earlier run's manifest so a failed extraction cannot leave
        // apparently valid metadata beside newly generated hardware.
        Files.deleteIfExists(destination);
        try {
            List<CoprocessorSpec.PortSpec> ports = new ArrayList<>();
            addPorts(ports, inputs, "input", protocol);
            addPorts(ports, outputs, "output", protocol);
            Map<Integer,String> finalIds = new TreeMap<>(configs.snapshotAssignedConfigMap());
            List<CoprocessorSpec.ModeSpec> modes = new ArrayList<>();
            List<String> warnings = new ArrayList<>();
            for (Map.Entry<Integer,String> entry : finalIds.entrySet()) {
                String name = entry.getValue();
                Network original = null;
                for (Network candidate : configs.getNetworkList()) {
                    if (name.equals(candidate.getSimpleName())) {
                        if (original != null) throw new IllegalArgumentException("ambiguous original network: " + name);
                        original = candidate;
                    }
                }
                Map<String,String> mapping = vertexMaps == null ? null : vertexMaps.get(name);
                List<String> active = new ArrayList<>();
                boolean known = original != null &&
                    (!original.getInputs().isEmpty() || !original.getOutputs().isEmpty());
                // Single, unmerged network may legitimately have no vertex map.
                boolean identity = original == network && finalIds.size() == 1;
                if (known) {
                    known = mapPorts(original.getInputs(), inputs, mapping, identity, "input", active)
                         && mapPorts(original.getOutputs(), outputs, mapping, identity, "output", active);
                }
                modes.add(new CoprocessorSpec.ModeSpec(entry.getKey(), name, known ? active : null,
                    known ? (identity && mapping == null ? "single_network_identity" : "original_network_ports_and_vertex_map")
                          : "unavailable"));
            }
            Set<String> configuredNames = new HashSet<>(finalIds.values());
            if (vertexMaps != null) for (String name : vertexMaps.keySet())
                if (!configuredNames.contains(name))
                    throw new IllegalArgumentException("vertex-map mode has no final configuration ID: " + name);
            CoprocessorSpec spec = new CoprocessorSpec(network.getSimpleName(), part, board,
                hasSwitches, ports, modes, warnings);
            Files.createDirectories(outputRoot);
            // Both JSON and Tcl settings are serialized from this same typed model.
            Kv260ScriptPrinter.write(outputRoot, spec);            
            Path temporary = Files.createTempFile(outputRoot, ".accelerator-", ".json.tmp");
            try {
                Files.write(temporary, spec.toJson().getBytes(StandardCharsets.UTF_8));
                try {
                    Files.move(temporary, destination, StandardCopyOption.ATOMIC_MOVE, StandardCopyOption.REPLACE_EXISTING);
                } catch (AtomicMoveNotSupportedException unsupported) {
                    Files.move(temporary, destination, StandardCopyOption.REPLACE_EXISTING);
                }
            } finally {
                Files.deleteIfExists(temporary);
            }
            OrccLogger.traceln("* Shared accelerator description: " + destination);
            OrccLogger.traceln("* KV260 scripts emitted from shared spec; Vivado build and Linux driver integration remain pending.");
            for (CoprocessorSpec.ModeSpec mode : modes) if (mode.activePortIds == null)
                OrccLogger.traceln("* Manifest: active ports unknown for " + mode.name + "; preserve original port metadata before deployment.");
        } catch (IllegalArgumentException error) {
            throw new IOException("Cannot generate accelerator.json: " + error.getMessage(), error);
        }
    }
    private static void addPorts(List<CoprocessorSpec.PortSpec> result, Map<Port,Integer> map,
                                 String direction, ProtocolManager protocol) {
        if (map == null) throw new IllegalArgumentException("wrapper port maps have not been initialized");
        for (Map.Entry<Port,Integer> e : map.entrySet()) {
            Port p = e.getKey();
            if (!(p.getType().isInt() || p.getType().isUint()))
                throw new IllegalArgumentException("scalar integer ports required by profile: " + p.getName());
            result.add(new CoprocessorSpec.PortSpec(p.getName(), direction, e.getValue(),
                p.getType().getSizeInBits(), protocol.getDataSize(p), p.getType().isInt()));
        }
    }
    private static boolean mapPorts(Iterable<Port> originals, Map<Port,Integer> targets,
            Map<String,String> mapping, boolean identity, String direction, List<String> active) {
        for (Port p : originals) {
            String mapped = mapping == null ? (identity ? p.getName() : null) : mapping.get(p.getName());
            if (mapped == null) return false;
            String id = null;
            for (Map.Entry<Port,Integer> e : targets.entrySet()) if (mapped.equals(e.getKey().getName())) {
                if (id != null) throw new IllegalArgumentException("ambiguous merged boundary port: " + mapped);
                if (!p.getType().equals(e.getKey().getType()))
                    throw new IllegalArgumentException("mapped boundary token type differs: " + mapped);
                id = direction + ":" + e.getValue();
            }
            if (id == null) throw new IllegalArgumentException("boundary mapping refers to missing " + direction + ": " + mapped);
            if (active.contains(id)) throw new IllegalArgumentException("two original boundary ports collapse onto " + id);
            active.add(id);
        }
        return true;
    }
}