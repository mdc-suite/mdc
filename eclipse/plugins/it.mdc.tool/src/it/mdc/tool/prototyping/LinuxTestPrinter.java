package it.mdc.tool.prototyping;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/** Emits the file-driven Linux test application from CoprocessorSpec.
 *
 * The application deliberately uses named ports and mode names from the
 * shared description.  It therefore cannot silently inherit a different DMA
 * channel order when the wrapper maps are regenerated.
 */
public final class LinuxTestPrinter {
    private LinuxTestPrinter() {}

    private static Map<?, ?> map(Object value) {
        return (Map<?, ?>) value;
    }

    private static List<?> list(Object value) {
        return (List<?>) value;
    }

    private static int integer(Object value) {
        return ((Number) value).intValue();
    }

    private static String string(Object value) {
        return value == null ? "" : value.toString();
    }

    private static String cQuote(String text) {
        StringBuilder out = new StringBuilder("\"");
        for (int i = 0; i < text.length(); ++i) {
            char c = text.charAt(i);
            switch (c) {
            case '\\': out.append("\\\\"); break;
            case '"': out.append("\\\""); break;
            case '\n': out.append("\\n"); break;
            case '\r': out.append("\\r"); break;
            case '\t': out.append("\\t"); break;
            default:
                if (c < 32 || c > 126)
                    throw new IllegalArgumentException("port/mode name is not printable: " + text);
                out.append(c);
            }
        }
        return out.append('"').toString();
    }

    /** Emit userspace/mdc_test.c, the generated descriptor header and TESTING.md. */
    public static void write(Path outputRoot, CoprocessorSpec spec) throws IOException {
        Map<String, Object> document = spec.toDocument();
        Path linux = outputRoot.resolve("linux");
        Path include = linux.resolve("include");
        Path userspace = linux.resolve("userspace");
        Files.createDirectories(include);
        Files.createDirectories(userspace);

        replace(userspace.resolve("mdc_test.c"), resource("mdc_test.c"));
        replace(include.resolve("mdc_test_config.h"), makeHeader(document));
        replace(linux.resolve("TESTING.md"), makeReadme(document));
        updateMakefile(linux.resolve("Makefile"));
    }

    private static String makeHeader(Map<String, Object> document) {
        List<?> ports = list(document.get("ports"));
        List<?> modes = list(document.get("modes"));
        Map<?, ?> software = map(document.get("linux_driver"));
        Map<String, Integer> channelById = new HashMap<>();
        StringBuilder out = new StringBuilder();
        out.append("/* Generated from CoprocessorSpec; do not edit. */\n")
           .append("#ifndef MDC_TEST_CONFIG_H\n#define MDC_TEST_CONFIG_H\n")
           .append("#include <stdint.h>\n\n")
           .append("#define MDC_TEST_DEVICE ").append(cQuote(string(software.get("device"))))
           .append("\n")
           .append("#define MDC_TEST_CHANNELS ").append(ports.size()).append("u\n")
           .append("#define MDC_TEST_OUTPUTS ").append(countDirection(ports, "output")).append("u\n")
           .append("#define MDC_TEST_MODE_COUNT ").append(modes.size()).append("u\n")
           .append("#define MDC_TEST_BUFFER_BYTES ")
           .append(integer(software.get("buffer_bytes_per_channel"))).append("u\n")
           .append("#define MDC_TEST_CONTROL_OFFSET 0u\n")
           .append("#define MDC_TEST_MODE_SHIFT 24u\n")
           .append("#define MDC_TEST_COUNTER_CLEAR_BIT 2u\n")
           .append("#define MDC_TEST_START_BIT 0u\n\n")
           .append("struct mdc_test_port {\n")
           .append("    const char *name;\n    unsigned channel;\n")
           .append("    unsigned direction;\n    unsigned token_bits;\n")
           .append("    unsigned register_offset;\n};\n\n")
           .append("struct mdc_test_mode { unsigned id; const char *name; };\n\n");

        out.append("static const struct mdc_test_port mdc_test_ports[MDC_TEST_CHANNELS] = {\n");
        for (int i = 0; i < ports.size(); ++i) {
            Map<?, ?> port = map(ports.get(i));
            String id = string(port.get("id"));
            channelById.put(id, Integer.valueOf(i));
            int offset = "output".equals(string(port.get("direction")))
                ? 4 * (integer(port.get("index")) + 1) : 0;
            out.append("    {").append(cQuote(string(port.get("name")))).append(", ")
               .append(i).append("u, ")
               .append("output".equals(string(port.get("direction"))) ? "0u" : "1u")
               .append(", ").append(integer(port.get("token_bits"))).append("u, ")
               .append(offset).append("u}")
               .append(i + 1 == ports.size() ? "\n" : ",\n");
        }
        out.append("};\n\n");

        out.append("static const struct mdc_test_mode mdc_test_modes[")
           .append(modes.size() == 0 ? "1" : "MDC_TEST_MODE_COUNT")
           .append("] = {");
        if (modes.isEmpty()) {
            out.append(" {0u, \"\"} ");
        } else {
            out.append("\n");
            for (int i = 0; i < modes.size(); ++i) {
                Map<?, ?> mode = map(modes.get(i));
                out.append("    {").append(integer(mode.get("id"))).append("u, ")
                   .append(cQuote(string(mode.get("name")))).append("}")
                   .append(i + 1 == modes.size() ? "\n" : ",\n");
            }
        }
        out.append("};\n\n");

        out.append("static const unsigned int mdc_test_mode_membership_known[")
           .append(modes.size() == 0 ? "1" : "MDC_TEST_MODE_COUNT")
           .append("] = {");
        if (modes.isEmpty()) out.append(" 0u ");
        else {
            for (int i = 0; i < modes.size(); ++i) {
                Map<?, ?> mode = map(modes.get(i));
                out.append(map(mode).get("active_port_ids") == null ? "0u" : "1u")
                   .append(i + 1 == modes.size() ? "" : ", ");
            }
        }
        out.append("};\n\n");

        out.append("static const uint32_t mdc_test_mode_active_masks[")
           .append(modes.size() == 0 ? "1" : "MDC_TEST_MODE_COUNT")
           .append("] = {");
        if (modes.isEmpty()) out.append(" UINT32_MAX ");
        else {
            for (int i = 0; i < modes.size(); ++i) {
                Map<?, ?> mode = map(modes.get(i));
                Object activeValue = mode.get("active_port_ids");
                long mask = 0xffffffffL;
                if (activeValue != null) {
                    mask = 0L;
                    for (Object value : list(activeValue)) {
                        Integer channel = channelById.get(string(value));
                        if (channel == null)
                            throw new IllegalArgumentException("mode refers to unknown port " + value);
                        mask |= 1L << channel.intValue();
                    }
                }
                out.append(String.format(java.util.Locale.ROOT, "UINT32_C(0x%08X)", mask))
                   .append(i + 1 == modes.size() ? "" : ", ");
            }
        }
        out.append("};\n\n#endif\n");
        return out.toString();
    }

    private static int countDirection(List<?> ports, String direction) {
        int count = 0;
        for (Object value : ports)
            if (direction.equals(string(map(value).get("direction")))) ++count;
        return count;
    }

    private static String makeReadme(Map<String, Object> document) {
        List<?> ports = list(document.get("ports"));
        List<?> modes = list(document.get("modes"));
        Map<?, ?> software = map(document.get("linux_driver"));
        String firstMode = modes.isEmpty() ? "<mode>" : string(map(modes.get(0)).get("name"));
        StringBuilder inputs = new StringBuilder();
        StringBuilder outputs = new StringBuilder();
        StringBuilder table = new StringBuilder();
        for (Object value : ports) {
            Map<?, ?> port = map(value);
            String name = string(port.get("name"));
            String direction = string(port.get("direction"));
            if ("input".equals(direction))
                inputs.append(" --input ").append(name).append("=").append(name).append("_" + firstMode + "_file.mem");
            else
                outputs.append(" --output ").append(name).append("=").append(name).append("_" + firstMode + "_actual.mem")
                    .append(" --expect ").append(name).append("=").append(name).append("_" + firstMode + "_file.mem");
            table.append("| ").append(name).append(" | ").append(port.get("index"))
                 .append(" | ").append(direction).append(" | ").append(port.get("token_bits"))
                 .append(" | ").append(port.get("id")).append(" |\n");
        }
        StringBuilder modeTable = new StringBuilder();
        for (Object value : modes) {
            Map<?, ?> mode = map(value);
            modeTable.append("| ").append(mode.get("name")).append(" | ")
                     .append(mode.get("id")).append(" | ");
            Object active = mode.get("active_port_ids");
            if (active == null) modeTable.append("all generated ports; membership unavailable");
            else modeTable.append(join(active));
            modeTable.append(" |\n");
        }
        return "# Generated file-driven MDC test\n\n" +
            "This directory contains `userspace/mdc_test`, generated from the same `CoprocessorSpec` as the KV260 wrapper, Linux driver and device-tree overlay. It is the software counterpart of `tb_multi_dataflow.v`: it selects one configuration, reads one token stream per input, arms every output, submits the inputs, waits for every active channel, writes received tokens, and optionally compares them with reference files.\n\n" +
            "## Build\n\n" +
            "Run from this generated Linux directory on the target board:\n\n" +
            "```sh\nmake userspace\n```\n\n" +
            "The driver, overlay, FPGA image and clock/reset sequence must already be loaded. The application uses the generated `/dev/mdc_accel0` ABI and `mdc_config.h`; it does not use the legacy `/dev/uniss_dma` interface.\n\n" +
            "## Ports and configurations\n\n" +
            "| name | index | direction | token bits | descriptor ID |\n|---|---:|---|---:|---|\n" + table +
            "\n| mode | ID | active ports |\n|---|---:|---|\n" + modeTable +
            "\nUse `./userspace/mdc_test --describe` to print this information on the board. Port names are intentional: do not substitute numeric channel order by hand.\n\n" +
            "## Input and output files\n\n" +
            "The runner accepts any filename extension, including `.mem`, `.data` and `.txt`. Files contain whitespace-separated unsigned tokens. The default `--format hex` matches Verilog `$readmemh`; `--format dec` reads decimal tokens and `--format auto` recognizes hexadecimal letters or a `0x` prefix. Blank lines, `#` comments and `//` comments are accepted. Verilog address directives (`@`), `x`, and `z` values are rejected deliberately. Each token is checked against its declared width and transferred in the low bits of one 32-bit word.\n\n" +
            "An output count is required because a streaming interface has no end-of-packet marker in this profile. Supplying `--expect name=file` obtains the count from the reference file; otherwise supply `--count name=N`. The received output is written as one uppercase hexadecimal token per line.\n\n" +
            "## Example equivalent to the generated Verilog testbench\n\n" +
            "```sh\n./userspace/mdc_test --mode " + firstMode + inputs + outputs +
            " --format hex --timeout-ms 10000\n```\n\n" +
            "For a test without a golden file, replace each `--expect name=file` with `--count name=N`. Use `--dry-run` before accessing hardware to validate all files and port names:\n\n" +
            "```sh\n./userspace/mdc_test --dry-run --mode " + firstMode + inputs + outputs +
            " --format hex\n```\n\n" +
            "The generated DMA capacity is " + software.get("buffer_bytes_per_channel") + " bytes per channel. The runner refuses longer transfers instead of silently truncating them. A successful transfer and a successful reference comparison are reported separately.\n";
    }

    private static String join(Object value) {
        StringBuilder out = new StringBuilder();
        for (Object item : list(value)) {
            if (out.length() != 0) out.append(", ");
            out.append(item);
        }
        return out.toString();
    }

    private static String resource(String name) throws IOException {
        String location = "/bundle/copr/linux/" + name;
        try (InputStream in = LinuxTestPrinter.class.getResourceAsStream(location)) {
            if (in == null) throw new IOException("Missing MDC Linux test resource: " + location);
            ByteArrayOutputStream bytes = new ByteArrayOutputStream();
            byte[] buffer = new byte[8192];
            int n;
            while ((n = in.read(buffer)) != -1) bytes.write(buffer, 0, n);
            return new String(bytes.toByteArray(), StandardCharsets.UTF_8);
        }
    }

    private static void replace(Path path, String content) throws IOException {
        Files.createDirectories(path.getParent());
        Path temporary = Files.createTempFile(path.getParent(), ".mdc-test-", ".tmp");
        try {
            Files.write(temporary, content.getBytes(StandardCharsets.UTF_8));
            Files.move(temporary, path, StandardCopyOption.REPLACE_EXISTING);
        } finally {
            Files.deleteIfExists(temporary);
        }
    }

    /** Add the test target without replacing the driver targets generated by Step 4. */
    private static void updateMakefile(Path makefile) throws IOException {
        if (!Files.exists(makefile)) return;
        String text = new String(Files.readAllBytes(makefile), StandardCharsets.UTF_8);
        if (!text.contains("userspace/mdc_test.c")) {
            int target = text.indexOf("userspace:");
            if (target >= 0) {
                int end = text.indexOf('\n', target);
                if (end < 0) end = text.length();
                text = text.substring(0, end) + " userspace/mdc_test" + text.substring(end);
            }
            text += "\nuserspace/mdc_test: userspace/mdc_test.c include/mdc_test_config.h include/mdc_user.h include/mdc_uapi.h include/mdc_config.h\n"
                  + "\t$(CC) $(CFLAGS) -Iinclude $< -o $@\n";
        }
        if (!text.contains("clean-test-metadata:")) {
            int clean = text.indexOf("clean:");
            if (clean >= 0) text = text.substring(0, clean + "clean:".length()) +
                " clean-test-metadata" + text.substring(clean + "clean:".length());
            text += "\n.PHONY: clean-test-metadata\nclean-test-metadata:\n\t$(RM) userspace/mdc_test\n";
        }
        replace(makefile, text);
    }
}
