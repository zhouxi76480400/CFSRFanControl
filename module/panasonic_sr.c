#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/acpi.h>
#include <linux/fs.h>
#include <linux/sysfs.h>
#include <linux/device.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Shi Chou");
MODULE_DESCRIPTION("Panasonic CF-SR Secure Fan Control Module");
MODULE_VERSION("1.0");

static struct class *panasonic_class;
static struct device *panasonic_device;

static int call_sefm(int val) {
    acpi_status status;
    union acpi_object arg0;
    struct acpi_object_list args;

    arg0.type = ACPI_TYPE_INTEGER;
    arg0.integer.value = val;

    args.count = 1;
    args.pointer = &arg0;

    status = acpi_evaluate_object(NULL, "\\_SB.PC00.LPCB.EC0.SEFM", &args, NULL);
    if (ACPI_FAILURE(status)) {
        pr_err("panasonic_sr: Failed to evaluate SEFM: %s\n", acpi_format_exception(status));
        return -EIO;
    }
    return 0;
}

static ssize_t sefm_show(struct device *dev, struct device_attribute *attr, char *buf) {
    return sprintf(buf, "Panasonic CF-SR Fan Control Active\n");
}

static ssize_t sefm_store(struct device *dev, struct device_attribute *attr, const char *buf, size_t count) {
    int val, ret;
    
    if (kstrtoint(buf, 10, &val) != 0)
        return -EINVAL;

    if (val != 0 && val != 1)
        return -EINVAL;

    ret = call_sefm(val);
    if (ret < 0)
        return ret;

    return count;
}
static DEVICE_ATTR_RW(sefm);

static int __init panasonic_sr4_init(void) {
    int ret;
    panasonic_class = class_create("panasonic_sr");
    if (IS_ERR(panasonic_class)) {
        return PTR_ERR(panasonic_class);
    }

    panasonic_device = device_create(panasonic_class, NULL, 0, NULL, "fan_control");
    if (IS_ERR(panasonic_device)) {
        class_destroy(panasonic_class);
        return PTR_ERR(panasonic_device);
    }

    ret = device_create_file(panasonic_device, &dev_attr_sefm);
    if (ret) {
        device_destroy(panasonic_class, 0);
        class_destroy(panasonic_class);
        return ret;
    }

    return 0;
}

static void __exit panasonic_sr4_exit(void) {
    device_remove_file(panasonic_device, &dev_attr_sefm);
    device_destroy(panasonic_class, 0);
    class_destroy(panasonic_class);
}

module_init(panasonic_sr4_init);
module_exit(panasonic_sr4_exit);