package it.mdc.tool.prototyping;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.Map;
import java.util.List;

/** JSON and Tcl are projections of the same CoprocessorSpec, never separate maps. */
public final class Kv260ScriptPrinter {
    private Kv260ScriptPrinter() {}
    public static void write(Path outputRoot, CoprocessorSpec spec) throws IOException {
        Path scripts = outputRoot.resolve("scripts");
        Files.createDirectories(scripts);
        // Require every bundled resource before replacing any generated script.
        String[] names = {"mdc_common.tcl", "generate_ip.tcl", "generate_top.tcl", "build_all.tcl"};
        String[] templates = new String[names.length];
        for (int i=0; i<names.length; i++) templates[i] = resource(names[i]);
        // Regeneration invalidates any package built from previous HDL.
        Files.deleteIfExists(scripts.resolve("packaged_ip.path"));
        StringBuilder settings = new StringBuilder("# Generated from CoprocessorSpec; do not edit.\nset mdc_spec ");
        tcl(spec.toDocument(), settings);
        settings.append("\nset mdc_manifest_json "); quote(spec.toJson(), settings); settings.append('\n');
        replace(scripts.resolve("accelerator_config.tcl"), settings.toString());
        for (int i=0; i<names.length; i++) replace(scripts.resolve(names[i]), templates[i]);
        LinuxDriverPrinter.write(outputRoot, spec);
    }
    private static String resource(String name) throws IOException {
        String location = "/bundle/copr/vivado/kv260/" + name;
        try (InputStream in = Kv260ScriptPrinter.class.getResourceAsStream(location)) {
            if (in == null) throw new IOException("Missing MDC bundle resource " + location);
            ByteArrayOutputStream bytes = new ByteArrayOutputStream(); byte[] buffer = new byte[8192]; int n;
            while ((n=in.read(buffer)) != -1) bytes.write(buffer,0,n);
            return new String(bytes.toByteArray(),StandardCharsets.UTF_8);
        }
    }
    private static void replace(Path path, String content) throws IOException {
        Path tmp=Files.createTempFile(path.getParent(), ".kv260-", ".tmp");
        try { Files.write(tmp,content.getBytes(StandardCharsets.UTF_8));
            Files.move(tmp,path,StandardCopyOption.REPLACE_EXISTING);
        } finally { Files.deleteIfExists(tmp); }
    }
    private static void quote(String text, StringBuilder out) {
        out.append('"');
        for (int i=0;i<text.length();i++) {
            char c=text.charAt(i);
            switch(c) {
            case '\\': case '"': case '$': case '[': case ']': out.append('\\').append(c);break;
            case '\n':out.append("\\n");break;
            case '\r':out.append("\\r");break;
            case '\t':out.append("\\t");break;
            default:
                if(c<32) out.append(String.format(java.util.Locale.ROOT,"\\u%04x",(int)c));
                else out.append(c);
            }
        }
        out.append('"');
    }
    private static void tcl(Object obj, StringBuilder out) {
        if(obj == null) {out.append("\"\"");return;}
        if(obj instanceof String) {quote((String)obj,out);return;}
        if(obj instanceof Number) {out.append(obj);return;}
        if(obj instanceof Boolean) {out.append((Boolean)obj ? "1" : "0");return;}
        if(obj instanceof Map) {
            out.append("[dict create");
            for(Map.Entry<?,?> e:((Map<?,?>)obj).entrySet()) {
                out.append(' ');quote((String)e.getKey(),out);out.append(' ');tcl(e.getValue(),out);
            }
            out.append(']');return;
        }
        if(obj instanceof List) {
            out.append("[list");
            for(Object v:(List<?>)obj) {out.append(' ');tcl(v,out);}
            out.append(']');return;
        }
        throw new IllegalArgumentException("Unsupported Tcl value");
    }
}
