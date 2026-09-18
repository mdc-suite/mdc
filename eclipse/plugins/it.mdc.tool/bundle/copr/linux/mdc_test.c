/* SPDX-License-Identifier: MIT */
/*
 * Generated MDC stream test runner.
 *
 * The generated mdc_test_config.h describes the channels, token widths and
 * configuration IDs.  Input, output and reference files are whitespace
 * separated text files.  The default format is hexadecimal, which matches
 * Verilog $readmemh files; .mem, .data and .txt are deliberately treated the
 * same way.  Every token is transported in the low bits of one 32-bit word.
 */
#define _POSIX_C_SOURCE 200809L

#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <inttypes.h>
#include <limits.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <unistd.h>

#include "mdc_config.h"
#include "mdc_test_config.h"
#include "mdc_uapi.h"
#include "mdc_user.h"

#ifndef MDC_TEST_DEVICE
#define MDC_TEST_DEVICE "/dev/mdc_accel0"
#endif

#define MDC_TEST_MAX_WORDS (MDC_TEST_BUFFER_BYTES / 4u)
#define MDC_TEST_MAX_SPEC 4096u

enum number_format {
    NUMBER_HEX,
    NUMBER_DECIMAL,
    NUMBER_AUTO
};

struct file_binding {
    const char *input_path;
    const char *output_path;
    const char *expect_path;
    uint32_t explicit_count;
    bool has_explicit_count;
    uint32_t *input_words;
    uint32_t *expected_words;
    uint32_t *output_words;
    size_t input_count;
    size_t expected_count;
    size_t output_count;
};

struct options {
    const char *device;
    const char *mode_text;
    enum number_format format;
    uint32_t timeout_ms;
    bool describe;
    bool dry_run;
    struct file_binding bindings[MDC_TEST_CHANNELS];
};

static void usage(const char *program)
{
    fprintf(stderr,
        "Usage: %s --mode NAME|ID [options]\n"
        "       %s --describe\n\n"
        "Options:\n"
        "  --input NAME=FILE       input token file (repeat for every input)\n"
        "  --output NAME=FILE      received output file (repeat for every output)\n"
        "  --expect NAME=FILE      expected output file for comparison\n"
        "  --count NAME=N          output token count when no --expect is given\n"
        "  --format hex|dec|auto   token format; default is hex ($readmemh)\n"
        "  --timeout-ms N          bounded wait timeout (1..60000, default 10000)\n"
        "  --device PATH           device node (default %s)\n"
        "  --dry-run               parse and validate files without opening hardware\n"
        "  --help                  show this message\n",
        program, program, MDC_TEST_DEVICE);
}

static int parse_u64(const char *text, unsigned base, uint64_t *value)
{
    char *end = NULL;
    unsigned long long parsed;

    if (text == NULL || *text == '\0' || text[0] == '-')
        return -1;
    errno = 0;
    parsed = strtoull(text, &end, base);
    if (errno != 0 || end == text || *end != '\0')
        return -1;
    *value = (uint64_t)parsed;
    return 0;
}

static int parse_u32(const char *text, unsigned base, uint32_t *value)
{
    uint64_t parsed;
    if (parse_u64(text, base, &parsed) != 0 || parsed > UINT32_MAX)
        return -1;
    *value = (uint32_t)parsed;
    return 0;
}

static int parse_number(const char *text, enum number_format format,
                        uint32_t *value)
{
    char normalized[128];
    size_t n = 0;
    const char *p;
    unsigned base;

    if (text == NULL || *text == '\0' || text[0] == '@')
        return -1;
    for (p = text; *p != '\0'; ++p) {
        if (n + 1 >= sizeof(normalized) || *p == 'z' || *p == 'Z')
            return -1;
        if (*p != '_')
            normalized[n++] = *p;
    }
    normalized[n] = '\0';
    if (n == 0)
        return -1;

    if (format == NUMBER_HEX)
        base = 16;
    else if (format == NUMBER_DECIMAL)
        base = 10;
    else {
        base = 10;
        if (normalized[0] == '0' &&
            (normalized[1] == 'x' || normalized[1] == 'X'))
            base = 16;
        for (p = normalized; *p != '\0'; ++p) {
            if (*p == 'a' || *p == 'b' || *p == 'c' || *p == 'd' ||
                *p == 'e' || *p == 'f' || *p == 'A' || *p == 'B' ||
                *p == 'C' || *p == 'D' || *p == 'E' || *p == 'F') {
                base = 16;
                break;
            }
        }
    }
    return parse_u32(normalized, base, value);
}

/* Remove comments and return the next whitespace-delimited token. */
static int next_token(FILE *file, char *token, size_t capacity,
                      unsigned *line_number, unsigned *token_line)
{
    int c;
    size_t length = 0;
    bool in_comment = false;
    bool slash_seen = false;

    for (;;) {
        c = fgetc(file);
        if (c == EOF)
            return 0;
        if (c == '\n') {
            ++*line_number;
            in_comment = false;
            slash_seen = false;
            continue;
        }
        if (in_comment)
            continue;
        if (c == '#') {
            in_comment = true;
            continue;
        }
        if (c == '/') {
            int next = fgetc(file);
            if (next == '/') {
                in_comment = true;
                continue;
            }
            if (next != EOF)
                ungetc(next, file);
            slash_seen = true;
        }
        if (isspace((unsigned char)c)) {
            slash_seen = false;
            continue;
        }
        *token_line = *line_number;
        token[length++] = (char)c;
        break;
    }

    while (length + 1 < capacity) {
        c = fgetc(file);
        if (c == EOF || isspace((unsigned char)c))
            break;
        if (c == '#') {
            in_comment = true;
            break;
        }
        if (c == '/') {
            int next = fgetc(file);
            if (next == '/') {
                in_comment = true;
                break;
            }
            if (next != EOF)
                ungetc(next, file);
        }
        token[length++] = (char)c;
    }
    if (length + 1 >= capacity) {
        fprintf(stderr, "input token is longer than %zu characters\n",
                capacity - 1);
        return -1;
    }
    token[length] = '\0';
    if (c == '\n')
        ++*line_number;
    if (in_comment) {
        while ((c = fgetc(file)) != EOF && c != '\n')
            ;
        if (c == '\n')
            ++*line_number;
    }
    (void)slash_seen;
    return 1;
}

static uint32_t width_mask(unsigned bits)
{
    if (bits >= 32u)
        return UINT32_MAX;
    return (uint32_t)((UINT64_C(1) << bits) - 1u);
}

static const struct mdc_test_port *find_port(const char *name)
{
    unsigned i;
    for (i = 0; i < MDC_TEST_CHANNELS; ++i)
        if (strcmp(name, mdc_test_ports[i].name) == 0)
            return &mdc_test_ports[i];
    return NULL;
}

static int split_assignment(const char *assignment, char *name,
                            size_t name_capacity, const char **path)
{
    const char *equals = strchr(assignment, '=');
    size_t length;
    if (equals == NULL || equals == assignment || equals[1] == '\0')
        return -1;
    length = (size_t)(equals - assignment);
    if (length + 1 > name_capacity)
        return -1;
    memcpy(name, assignment, length);
    name[length] = '\0';
    *path = equals + 1;
    return 0;
}

static int bind_path(struct file_binding *bindings, const char *assignment,
                     bool input, bool expected)
{
    char name[128];
    const char *path;
    const struct mdc_test_port *port;
    if (split_assignment(assignment, name, sizeof(name), &path) != 0) {
        fprintf(stderr, "invalid NAME=FILE assignment: %s\n", assignment);
        return -1;
    }
    port = find_port(name);
    if (port == NULL) {
        fprintf(stderr, "unknown port '%s'\n", name);
        return -1;
    }
    if (input && port->direction != MDC_MM2S) {
        fprintf(stderr, "port '%s' is an output, not an input\n", name);
        return -1;
    }
    if (!input && port->direction != MDC_S2MM) {
        fprintf(stderr, "port '%s' is an input, not an output\n", name);
        return -1;
    }
    if (expected) {
        if (bindings[port->channel].expect_path != NULL) {
            fprintf(stderr, "duplicate --expect for port '%s'\n", name);
            return -1;
        }
        bindings[port->channel].expect_path = path;
    } else if (input) {
        if (bindings[port->channel].input_path != NULL) {
            fprintf(stderr, "duplicate --input for port '%s'\n", name);
            return -1;
        }
        bindings[port->channel].input_path = path;
    } else {
        if (bindings[port->channel].output_path != NULL) {
            fprintf(stderr, "duplicate --output for port '%s'\n", name);
            return -1;
        }
        bindings[port->channel].output_path = path;
    }
    return 0;
}

static int bind_count(struct file_binding *bindings, const char *assignment)
{
    char name[128];
    const char *text;
    uint32_t count;
    const struct mdc_test_port *port;
    if (split_assignment(assignment, name, sizeof(name), &text) != 0 ||
        parse_u32(text, 10, &count) != 0 || count == 0u) {
        fprintf(stderr, "invalid output count NAME=N: %s\n", assignment);
        return -1;
    }
    port = find_port(name);
    if (port == NULL || port->direction != MDC_S2MM) {
        fprintf(stderr, "--count requires an output port: %s\n", name);
        return -1;
    }
    if (bindings[port->channel].has_explicit_count) {
        fprintf(stderr, "duplicate --count for port '%s'\n", name);
        return -1;
    }
    bindings[port->channel].has_explicit_count = true;
    bindings[port->channel].explicit_count = count;
    return 0;
}

static int parse_mode(const char *text, uint32_t *mode_id)
{
    unsigned i;
    uint32_t numeric;
    for (i = 0; i < MDC_TEST_MODE_COUNT; ++i) {
        if (strcmp(text, mdc_test_modes[i].name) == 0) {
            *mode_id = mdc_test_modes[i].id;
            return 0;
        }
    }
    if (parse_u32(text, 10, &numeric) != 0 || numeric > 255u)
        return -1;
    for (i = 0; i < MDC_TEST_MODE_COUNT; ++i)
        if (mdc_test_modes[i].id == numeric) {
            *mode_id = numeric;
            return 0;
        }
    return -1;
}

static int mode_index(uint32_t mode_id)
{
    unsigned i;
    for (i = 0; i < MDC_TEST_MODE_COUNT; ++i)
        if (mdc_test_modes[i].id == mode_id)
            return (int)i;
    return -1;
}

static int load_words(const char *filename, enum number_format format,
                      unsigned token_bits, uint32_t **words_out,
                      size_t *count_out)
{
    FILE *file;
    uint32_t *words;
    char token[128];
    unsigned line = 1;
    unsigned token_line = 1;
    size_t count = 0;
    uint32_t value;
    int status;
    uint32_t mask = width_mask(token_bits);

    file = fopen(filename, "r");
    if (file == NULL) {
        fprintf(stderr, "%s: %s\n", filename, strerror(errno));
        return -1;
    }
    words = calloc(MDC_TEST_MAX_WORDS, sizeof(*words));
    if (words == NULL) {
        fprintf(stderr, "cannot allocate token buffer for %s\n", filename);
        fclose(file);
        return -1;
    }
    while ((status = next_token(file, token, sizeof(token), &line,
                                &token_line)) > 0) {
        if (count == MDC_TEST_MAX_WORDS) {
            fprintf(stderr, "%s: more than %u tokens; increase the generated "
                    "DMA buffer or split the transfer\n", filename,
                    MDC_TEST_MAX_WORDS);
            free(words);
            fclose(file);
            return -1;
        }
        if (parse_number(token, format, &value) != 0) {
            fprintf(stderr, "%s:%u: invalid %s token '%s'\n", filename,
                    token_line, format == NUMBER_HEX ? "hexadecimal" :
                    format == NUMBER_DECIMAL ? "decimal" : "numeric", token);
            free(words);
            fclose(file);
            return -1;
        }
        if ((value & ~mask) != 0u) {
            fprintf(stderr, "%s:%u: value 0x%08" PRIX32
                    " exceeds the %u-bit port width\n", filename, token_line,
                    value, token_bits);
            free(words);
            fclose(file);
            return -1;
        }
        words[count++] = value;
    }
    fclose(file);
    if (status < 0 || count == 0u) {
        if (count == 0u)
            fprintf(stderr, "%s: file contains no tokens\n", filename);
        free(words);
        return -1;
    }
    *words_out = words;
    *count_out = count;
    return 0;
}

static int validate_bindings(struct options *options, uint32_t mode_id)
{
    int index = mode_index(mode_id);
    uint32_t active_mask = UINT32_MAX;
    bool membership_known = false;
    unsigned i;

    if (index < 0)
        return -1;
    membership_known = mdc_test_mode_membership_known[index] != 0u;
    if (membership_known)
        active_mask = mdc_test_mode_active_masks[index];

    for (i = 0; i < MDC_TEST_CHANNELS; ++i) {
        const struct mdc_test_port *port = &mdc_test_ports[i];
        struct file_binding *binding = &options->bindings[i];
        bool active = (active_mask & (UINT32_C(1) << i)) != 0u;
        if (!active) {
            if (binding->input_path != NULL || binding->output_path != NULL ||
                binding->expect_path != NULL || binding->has_explicit_count) {
                fprintf(stderr, "port '%s' is inactive for mode %s\n",
                        port->name, mdc_test_modes[index].name);
                return -1;
            }
            continue;
        }
        if (port->direction == MDC_MM2S) {
            if (binding->input_path == NULL) {
                fprintf(stderr, "missing --input %s=FILE for mode %s\n",
                        port->name, mdc_test_modes[index].name);
                return -1;
            }
            if (load_words(binding->input_path, options->format,
                           port->token_bits, &binding->input_words,
                           &binding->input_count) != 0)
                return -1;
        } else {
            if (binding->output_path == NULL) {
                fprintf(stderr, "missing --output %s=FILE for mode %s\n",
                        port->name, mdc_test_modes[index].name);
                return -1;
            }
            if (binding->expect_path != NULL) {
                if (load_words(binding->expect_path, options->format,
                               port->token_bits, &binding->expected_words,
                               &binding->expected_count) != 0)
                    return -1;
            }
            if (binding->has_explicit_count) {
                binding->output_count = binding->explicit_count;
                if (binding->expected_words != NULL &&
                    binding->expected_count != binding->output_count) {
                    fprintf(stderr, "--count for %s (%u) differs from "
                            "reference length (%zu)\n", port->name,
                            binding->explicit_count, binding->expected_count);
                    return -1;
                }
            } else if (binding->expected_words != NULL) {
                binding->output_count = binding->expected_count;
            } else {
                fprintf(stderr, "output %s requires --count or --expect\n",
                        port->name);
                return -1;
            }
            if (binding->output_count == 0u ||
                binding->output_count > MDC_TEST_MAX_WORDS) {
                fprintf(stderr, "output %s count is outside the generated "
                        "buffer capacity (%u words)\n", port->name,
                        MDC_TEST_MAX_WORDS);
                return -1;
            }
            binding->output_words = calloc(binding->output_count,
                                           sizeof(*binding->output_words));
            if (binding->output_words == NULL) {
                fprintf(stderr, "cannot allocate output %s\n", port->name);
                return -1;
            }
        }
    }
    return 0;
}

static void free_bindings(struct file_binding *bindings)
{
    unsigned i;
    for (i = 0; i < MDC_TEST_CHANNELS; ++i) {
        free(bindings[i].input_words);
        free(bindings[i].expected_words);
        free(bindings[i].output_words);
    }
}

static void print_description(void)
{
    unsigned i;
    printf("device=%s buffer_bytes=%u channels=%u outputs=%u\n",
           MDC_TEST_DEVICE, MDC_TEST_BUFFER_BYTES, MDC_TEST_CHANNELS,
           MDC_TEST_OUTPUTS);
    printf("ports:\n");
    for (i = 0; i < MDC_TEST_CHANNELS; ++i) {
        const struct mdc_test_port *p = &mdc_test_ports[i];
        printf("  %s: channel=%u direction=%s token_bits=%u\n", p->name,
               p->channel, p->direction == MDC_MM2S ? "input" : "output",
               p->token_bits);
    }
    printf("modes:\n");
    for (i = 0; i < MDC_TEST_MODE_COUNT; ++i) {
        unsigned j;
        printf("  %s: id=%u active_ports=", mdc_test_modes[i].name,
               mdc_test_modes[i].id);
        if (!mdc_test_mode_membership_known[i]) {
            printf("all generated ports (membership unavailable)\n");
            continue;
        }
        for (j = 0; j < MDC_TEST_CHANNELS; ++j)
            if (mdc_test_mode_active_masks[i] & (UINT32_C(1) << j))
                printf("%s%s", j == 0 ? "" : ",", mdc_test_ports[j].name);
        putchar('\n');
    }
}

static int write_words(const char *filename, const uint32_t *words,
                       size_t count, unsigned token_bits)
{
    FILE *file = fopen(filename, "w");
    size_t i;
    unsigned digits = (token_bits + 3u) / 4u;
    if (file == NULL) {
        fprintf(stderr, "%s: %s\n", filename, strerror(errno));
        return -1;
    }
    for (i = 0; i < count; ++i)
        if (fprintf(file, "%0*" PRIX32 "\n", (int)digits,
                    words[i] & width_mask(token_bits)) < 0) {
            fprintf(stderr, "%s: write failed\n", filename);
            fclose(file);
            return -1;
        }
    if (fclose(file) != 0) {
        fprintf(stderr, "%s: close failed\n", filename);
        return -1;
    }
    return 0;
}

static int compare_words(const struct mdc_test_port *port,
                         const struct file_binding *binding)
{
    size_t i;
    uint32_t mask = width_mask(port->token_bits);
    if (binding->expected_words == NULL)
        return 0;
    if (binding->expected_count != binding->output_count) {
        fprintf(stderr, "%s: received %zu tokens, expected %zu\n",
                port->name, binding->output_count, binding->expected_count);
        return -1;
    }
    for (i = 0; i < binding->output_count; ++i) {
        uint32_t actual = binding->output_words[i] & mask;
        uint32_t expected = binding->expected_words[i] & mask;
        if (actual != expected) {
            fprintf(stderr, "%s: mismatch at token %zu: got 0x%08" PRIX32
                    ", expected 0x%08" PRIX32 "\n", port->name, i,
                    actual, expected);
            return -1;
        }
    }
    printf("%s: reference verified (%zu tokens)\n", port->name,
           binding->output_count);
    return 0;
}

static int configure(struct options *options, int fd, uint32_t mode_id)
{
    unsigned i;
    uint32_t control;
    if (ioctl(fd, MDC_RESET_ALL) != 0) {
        perror("MDC_RESET_ALL");
        return -1;
    }
    for (i = 0; i < MDC_TEST_CHANNELS; ++i) {
        const struct mdc_test_port *p = &mdc_test_ports[i];
        const struct file_binding *b = &options->bindings[i];
        if (p->direction == MDC_S2MM &&
            mdc_test_mode_active_masks[mode_index(mode_id)] &
            (UINT32_C(1) << i)) {
            if (mdc_reg_write(fd, p->register_offset,
                              (uint32_t)b->output_count) != 0) {
                fprintf(stderr, "cannot write output count for %s: %s\n",
                        p->name, strerror(errno));
                return -1;
            }
        }
    }
    control = (mode_id << MDC_TEST_MODE_SHIFT) |
              (UINT32_C(1) << MDC_TEST_COUNTER_CLEAR_BIT);
    if (mdc_reg_write(fd, MDC_TEST_CONTROL_OFFSET, control) != 0) {
        perror("MDC_REG_WRITE counter clear");
        return -1;
    }
    control = (mode_id << MDC_TEST_MODE_SHIFT) |
              (UINT32_C(1) << MDC_TEST_START_BIT);
    if (mdc_reg_write(fd, MDC_TEST_CONTROL_OFFSET, control) != 0) {
        perror("MDC_REG_WRITE start");
        return -1;
    }
    return 0;
}

static int run_hardware(struct options *options, int fd, uint32_t mode_id)
{
    unsigned i;
    struct mdc_info info;
    struct mdc_transfer result;
    int mode = mode_index(mode_id);
    uint32_t active_mask = mdc_test_mode_membership_known[mode] ?
                           mdc_test_mode_active_masks[mode] : UINT32_MAX;

    memset(&info, 0, sizeof(info));
    if (ioctl(fd, MDC_GET_INFO, &info) != 0) {
        perror("MDC_GET_INFO");
        return -1;
    }
    if (info.abi != MDC_ABI_VERSION || info.channels != MDC_TEST_CHANNELS ||
        info.output_ports != MDC_TEST_OUTPUTS ||
        info.buffer_bytes < MDC_TEST_BUFFER_BYTES) {
        fprintf(stderr, "driver contract mismatch: ABI=%u channels=%u "
                "outputs=%u buffer=%u\n", info.abi, info.channels,
                info.output_ports, info.buffer_bytes);
        return -1;
    }
    for (i = 0; i < MDC_TEST_CHANNELS; ++i) {
        const struct file_binding *b = &options->bindings[i];
        if ((active_mask & (UINT32_C(1) << i)) == 0u)
            continue;
        if ((b->input_count > 0u && b->input_count > MDC_TEST_MAX_WORDS) ||
            (b->output_count > MDC_TEST_MAX_WORDS)) {
            fprintf(stderr, "channel %s exceeds the driver buffer\n",
                    mdc_test_ports[i].name);
            return -1;
        }
    }
    if (configure(options, fd, mode_id) != 0)
        return -1;

    /* Arm all receive channels before transmitting any input token. */
    for (i = 0; i < MDC_TEST_CHANNELS; ++i) {
        const struct mdc_test_port *p = &mdc_test_ports[i];
        const struct file_binding *b = &options->bindings[i];
        uint32_t bytes;
        if ((active_mask & (UINT32_C(1) << i)) == 0u ||
            p->direction != MDC_S2MM)
            continue;
        bytes = (uint32_t)(b->output_count * sizeof(uint32_t));
        if (mdc_submit(fd, i, NULL, bytes) != 0) {
            fprintf(stderr, "MDC_SUBMIT output %s: %s\n", p->name,
                    strerror(errno));
            return -1;
        }
    }
    for (i = 0; i < MDC_TEST_CHANNELS; ++i) {
        const struct mdc_test_port *p = &mdc_test_ports[i];
        const struct file_binding *b = &options->bindings[i];
        uint32_t bytes;
        if ((active_mask & (UINT32_C(1) << i)) == 0u ||
            p->direction != MDC_MM2S)
            continue;
        bytes = (uint32_t)(b->input_count * sizeof(uint32_t));
        if (mdc_submit(fd, i, b->input_words, bytes) != 0) {
            fprintf(stderr, "MDC_SUBMIT input %s: %s\n", p->name,
                    strerror(errno));
            return -1;
        }
    }
    printf("DMA transfers submitted for mode %s (id=%u)\n",
           mdc_test_modes[mode].name, mode_id);

    for (i = 0; i < MDC_TEST_CHANNELS; ++i) {
        const struct mdc_test_port *p = &mdc_test_ports[i];
        if ((active_mask & (UINT32_C(1) << i)) == 0u)
            continue;
        memset(&result, 0, sizeof(result));
        if (mdc_wait(fd, i, options->timeout_ms, &result) != 0) {
            fprintf(stderr, "MDC_WAIT %s failed: %s status=0x%08" PRIX32
                    " actual=%u\n", p->name, strerror(errno), result.status,
                    result.actual);
            return -1;
        }
        printf("%s completed: status=0x%08" PRIX32 " bytes=%u\n",
               p->name, result.status, result.actual);
    }
    for (i = 0; i < MDC_TEST_CHANNELS; ++i) {
        const struct mdc_test_port *p = &mdc_test_ports[i];
        struct file_binding *b = &options->bindings[i];
        uint32_t actual = 0;
        if ((active_mask & (UINT32_C(1) << i)) == 0u ||
            p->direction != MDC_S2MM)
            continue;
        if (mdc_fetch(fd, i, b->output_words,
                      (uint32_t)(b->output_count * sizeof(uint32_t)),
                      &actual) != 0) {
            fprintf(stderr, "MDC_FETCH %s: %s\n", p->name, strerror(errno));
            return -1;
        }
        if (actual != b->output_count * sizeof(uint32_t)) {
            fprintf(stderr, "%s: received %u bytes, expected %zu\n",
                    p->name, actual, b->output_count * sizeof(uint32_t));
            return -1;
        }
        if (write_words(b->output_path, b->output_words, b->output_count,
                        p->token_bits) != 0 || compare_words(p, b) != 0)
            return -1;
    }
    return 0;
}

static int parse_options(int argc, char **argv, struct options *options)
{
    int i;
    memset(options, 0, sizeof(*options));
    options->device = MDC_TEST_DEVICE;
    options->format = NUMBER_HEX;
    options->timeout_ms = 10000u;
    for (i = 1; i < argc; ++i) {
        const char *arg = argv[i];
        if (strcmp(arg, "--help") == 0) {
            usage(argv[0]);
            return 1;
        }
        if (strcmp(arg, "--describe") == 0) {
            options->describe = true;
            continue;
        }
        if (strcmp(arg, "--dry-run") == 0) {
            options->dry_run = true;
            continue;
        }
        if (strcmp(arg, "--mode") == 0 || strcmp(arg, "--input") == 0 ||
            strcmp(arg, "--output") == 0 || strcmp(arg, "--expect") == 0 ||
            strcmp(arg, "--count") == 0 || strcmp(arg, "--format") == 0 ||
            strcmp(arg, "--timeout-ms") == 0 || strcmp(arg, "--device") == 0) {
            const char *value;
            if (++i >= argc) {
                fprintf(stderr, "%s requires a value\n", arg);
                return -1;
            }
            value = argv[i];
            if (strcmp(arg, "--mode") == 0)
                options->mode_text = value;
            else if (strcmp(arg, "--input") == 0 &&
                     bind_path(options->bindings, value, true, false) != 0)
                return -1;
            else if (strcmp(arg, "--output") == 0 &&
                     bind_path(options->bindings, value, false, false) != 0)
                return -1;
            else if (strcmp(arg, "--expect") == 0 &&
                     bind_path(options->bindings, value, false, true) != 0)
                return -1;
            else if (strcmp(arg, "--count") == 0 &&
                     bind_count(options->bindings, value) != 0)
                return -1;
            else if (strcmp(arg, "--format") == 0) {
                if (strcmp(value, "hex") == 0)
                    options->format = NUMBER_HEX;
                else if (strcmp(value, "dec") == 0 ||
                         strcmp(value, "decimal") == 0)
                    options->format = NUMBER_DECIMAL;
                else if (strcmp(value, "auto") == 0)
                    options->format = NUMBER_AUTO;
                else {
                    fprintf(stderr, "format must be hex, dec or auto\n");
                    return -1;
                }
            } else if (strcmp(arg, "--timeout-ms") == 0) {
                if (parse_u32(value, 10, &options->timeout_ms) != 0 ||
                    options->timeout_ms == 0u || options->timeout_ms > 60000u) {
                    fprintf(stderr, "timeout must be in the range 1..60000\n");
                    return -1;
                }
            } else if (strcmp(arg, "--device") == 0)
                options->device = value;
            continue;
        }
        fprintf(stderr, "unknown argument: %s\n", arg);
        return -1;
    }
    if (options->describe)
        return 0;
    if (options->mode_text == NULL) {
        fprintf(stderr, "--mode is required (or use --describe)\n");
        return -1;
    }
    return 0;
}

int main(int argc, char **argv)
{
    struct options options;
    uint32_t mode_id;
    int fd = -1;
    int result;

    result = parse_options(argc, argv, &options);
    if (result != 0)
        return result < 0 ? EXIT_FAILURE : EXIT_SUCCESS;
    if (options.describe) {
        print_description();
        return EXIT_SUCCESS;
    }
    if (parse_mode(options.mode_text, &mode_id) != 0) {
        fprintf(stderr, "unknown mode '%s'; use --describe\n", options.mode_text);
        return EXIT_FAILURE;
    }
    if (validate_bindings(&options, mode_id) != 0) {
        free_bindings(options.bindings);
        return EXIT_FAILURE;
    }
    if (options.dry_run) {
        printf("dry-run: mode %s (id=%u) is valid; no device opened\n",
               mdc_test_modes[mode_index(mode_id)].name, mode_id);
        free_bindings(options.bindings);
        return EXIT_SUCCESS;
    }
    fd = open(options.device, O_RDWR | O_CLOEXEC);
    if (fd < 0) {
        fprintf(stderr, "%s: %s\n", options.device, strerror(errno));
        free_bindings(options.bindings);
        return EXIT_FAILURE;
    }
    result = run_hardware(&options, fd, mode_id);
    close(fd);
    free_bindings(options.bindings);
    return result == 0 ? EXIT_SUCCESS : EXIT_FAILURE;
}
