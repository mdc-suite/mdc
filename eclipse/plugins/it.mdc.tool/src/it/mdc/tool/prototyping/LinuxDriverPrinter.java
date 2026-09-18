package it.mdc.tool.prototyping;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.List;
import java.util.Map;

/** Linux artifacts derived from the same hardware model; no hardware changes.
 * ABI is deliberately separate from the legacy uniss ioctl interface.
 */
public final class LinuxDriverPrinter {
    private LinuxDriverPrinter() {}
    private static Map<?,?> map(Object o) { return (Map<?,?>)o; }
    private static List<?> list(Object o) { return (List<?>)o; }
    private static String hex(Object o) { return String.format(java.util.Locale.ROOT,"0x%08x",Long.decode(o.toString())); }
    public static void write(Path outputRoot, CoprocessorSpec spec) throws IOException {
        Map<String,Object> doc = spec.toDocument();
        Map<?,?> plan = map(doc.get("hardware_plan"));
        if (!Integer.valueOf(32).equals(plan.get("dma_address_bits")) ||
            !Integer.valueOf(23).equals(plan.get("dma_length_bits")) ||
            !"0x80000000".equals(plan.get("ddr_low_range")) ||
            !"0x00000000".equals(plan.get("ddr_low_base")))
            throw new IOException("Linux ABI 1 requires the Step-3 low-DDR/simple-DMA profile");
        Map<?,?> software = map(doc.get("linux_driver"));
        if (!Integer.valueOf(1).equals(software.get("abi_version")) ||
            !Integer.valueOf(32).equals(software.get("dma_mask_bits")) ||
            !"polling".equals(software.get("completion")) ||
            !"/dev/mdc_accel0".equals(software.get("device")))
            throw new IOException("Unsupported Linux ABI/device/DMA policy");
        int bufferBytes = ((Number)software.get("buffer_bytes_per_channel")).intValue();
        if (bufferBytes <= 0 || bufferBytes % 4 != 0 || bufferBytes >= (1 << 23))
            throw new IOException("Invalid Linux DMA buffer capacity");
        List<?> dmas = list(plan.get("dma_controllers"));
        List<?> ports = list(doc.get("ports"));
        List<?> modes = list(doc.get("modes"));
        int outputs=0;
        StringBuilder directions=new StringBuilder(), bases=new StringBuilder(hex(plan.get("control_base_address"))+"ULL");
        for(Object value:dmas) {
            Map<?,?> d=map(value);
            if(directions.length()>0) directions.append(", ");
            directions.append("MM2S".equals(d.get("direction")) ? "1" : "0");
            bases.append(", ").append(hex(d.get("base_address"))).append("ULL");
        }
        for(Object p:ports) if("output".equals(map(p).get("direction"))) outputs++;
        StringBuilder ids=new StringBuilder();
        for(Object value:modes) { if(ids.length()>0)ids.append(", "); ids.append(map(value).get("id")); }
        if(ids.length()==0)ids.append("0"); // sentinel; MDC_MODES stays zero.
        String header="/* Generated from CoprocessorSpec; do not edit. */\n#ifndef MDC_CONFIG_H\n#define MDC_CONFIG_H\n"+
            "#define MDC_CHANNELS "+dmas.size()+"u\n#define MDC_OUTPUTS "+outputs+"u\n#define MDC_MODES "+modes.size()+"u\n"+
            "#define MDC_BUFFER_BYTES "+bufferBytes+"u\n"+
            "static const unsigned int mdc_directions[MDC_CHANNELS] = {"+directions+"};\n"+
            "static const unsigned int mdc_modes[] = {"+ids+"};\n"+
            "static const unsigned long long mdc_bases[MDC_CHANNELS+1] = {"+bases+"};\n#endif\n";
        StringBuilder dts=new StringBuilder("/dts-v1/;\n/plugin/;\n/* Hardware must be loaded separately before this overlay binds.\n * KV260 root address/size cells are both 2. No dma-coherent assertion.\n * This single driver owns all listed register windows.\n */\n/ {\n  fragment@0 {\n    target-path = \"/\";\n    __overlay__ {\n      #address-cells = <2>;\n      #size-cells = <2>;\n      mdc_accel: mdc-accelerator@");
        dts.append(hex(plan.get("control_base_address")).substring(2)).append(" {\n        compatible = \"mdc,kv260-stream-v1\";\n        status = \"okay\";\n        reg = <0 ").append(hex(plan.get("control_base_address"))).append(" 0 0x10000>");
        for(Object value:dmas)dts.append(",\n              <0 ").append(hex(map(value).get("base_address"))).append(" 0 0x10000>");
        dts.append(";\n        reg-names = \"control\"");
        for(int i=0;i<dmas.size();i++)dts.append(", \"dma").append(i).append("\"");
        dts.append(";\n      };\n    };\n  };\n};\n");
        // Load every resource before touching prior artifacts.
        String[] names={"mdc_dma.c","mdc_uapi.h","mdc_user.h","mdc_probe.c","mdc_run.c","Makefile","README.md"};
        String[] dest={"driver/mdc_dma.c","include/mdc_uapi.h","include/mdc_user.h","userspace/mdc_probe.c","userspace/mdc_run.c","Makefile","README.md"};
        String[] content=new String[names.length];
        for(int i=0;i<names.length;i++)content[i]=resource(names[i]);
        Path linux=outputRoot.resolve("linux");
        for(int i=0;i<names.length;i++)replace(linux.resolve(dest[i]),content[i]);
        replace(linux.resolve("driver/Makefile"),"obj-m += mdc_dma.o\nccflags-y += -I$(src)/../include\n");
        replace(linux.resolve("include/mdc_config.h"),header);
        replace(linux.resolve("device-tree/pl_mdc.dts"),dts.toString());
        replace(linux.resolve("accelerator.json"),spec.toJson());
        replace(linux.resolve("software.json"),"{\n  \"abi_version\": 1,\n  \"device\": \"/dev/mdc_accel0\",\n  \"compatible\": \"mdc,kv260-stream-v1\",\n  \"generation_stage\": \"linux_sources_emitted\",\n  \"deployment_verified\": false,\n  \"legacy_uniss_abi_compatible\": false,\n  \"buffer_bytes_per_channel\": "+bufferBytes+",\n  \"dma_mask_bits\": 32,\n  \"completion\": \"polling\"\n}\n");
        // Emit the named, file-driven C test from the same shared specification.
        LinuxTestPrinter.write(outputRoot, spec);
    }
    private static String resource(String name) throws IOException {
        try(InputStream in=LinuxDriverPrinter.class.getResourceAsStream("/bundle/copr/linux/"+name)) {
            if(in==null)throw new IOException("Missing MDC Linux resource: "+name);
            ByteArrayOutputStream b=new ByteArrayOutputStream();byte[] buffer=new byte[8192];int n;
            while((n=in.read(buffer))!=-1)b.write(buffer,0,n);
            return new String(b.toByteArray(),StandardCharsets.UTF_8);
        }
    }
    private static void replace(Path path,String content)throws IOException {
        Files.createDirectories(path.getParent());
        Path tmp=Files.createTempFile(path.getParent(),".mdc-linux-",".tmp");
        try { Files.write(tmp,content.getBytes(StandardCharsets.UTF_8)); Files.move(tmp,path,StandardCopyOption.REPLACE_EXISTING); }
        finally { Files.deleteIfExists(tmp); }
    }
}
