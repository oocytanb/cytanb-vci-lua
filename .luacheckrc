std = "lua52"
files["src/**/*_spec.lua"].std = "+busted"

max_line_length = false

globals = {
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
    "onUngrab"
}

self = false

ignore = {
    "212",
    "213",
    "231",
    "311",
    "211/cytanb"
}
