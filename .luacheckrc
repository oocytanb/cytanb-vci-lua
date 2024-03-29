std = "lua52"
files["src/**/*_spec.lua"].std = "+busted"
files["src/cytanb_min.lua"] = { ignore = { "211" } }

max_line_length = false

globals = {
    "utf8",
    "string.contains", "string.startsWith", "string.endsWith", "string.unicode",
    "_MOONSHARP",
    "dynamic",
    "json",
    "vci",
    "Vector2",
    "Vector3",
    "Vector4",
    "Color",
    "Quaternion",
    "Matrix4x4",
    "TimeSpan",
    "update",
    "updateAll",
    "onUse",
    "onUnuse",
    "onTriggerEnter",
    "onTriggerExit",
    "onCollisionEnter",
    "onCollisionExit",
    "onGrab",
    "onUngrab",
    "__CYTANB_EXPORT_MODULE",
    "cytanb"
}

self = false

ignore = {
    "212",
    "213",
    "231",
    "311",
    "211/cytanb"
}
