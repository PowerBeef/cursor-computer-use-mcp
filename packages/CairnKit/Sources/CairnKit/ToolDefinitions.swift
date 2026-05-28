import Foundation

public struct ToolDefinition: @unchecked Sendable {
    public let name: String
    public let description: String
    public let annotations: [String: Any]
    public let inputSchema: [String: Any]

    public init(name: String, description: String, annotations: [String: Any], inputSchema: [String: Any]) {
        self.name = name
        self.description = description
        self.annotations = annotations
        self.inputSchema = inputSchema
    }

    public var asDictionary: [String: Any] {
        var dictionary: [String: Any] = [
            "name": name,
            "description": description,
            "inputSchema": inputSchema,
        ]

        if !annotations.isEmpty {
            dictionary["annotations"] = annotations
        }

        return dictionary
    }
}

public enum ToolDefinitions {
    private static let elementIndexDescription =
        "Decimal string matching the line prefix from the latest get_app_state tree (e.g. \"14\"), or stable_id (e.g. \"id:abc123\")."

    public static let all: [ToolDefinition] = [
        ToolDefinition(
            name: "click",
            description: "Click a control by element_index, or by x/y in screenshot pixel coordinates from the latest get_app_state PNG.",
            annotations: defaultAnnotations(),
            inputSchema: objectSchema(
                properties: [
                    "app": stringProperty(description: "App name or bundle identifier"),
                    "element_index": stringProperty(description: elementIndexDescription),
                    "x": numberProperty(description: "X in screenshot pixel space (use with y; mutually exclusive with element_index)"),
                    "y": numberProperty(description: "Y in screenshot pixel space (use with x; mutually exclusive with element_index)"),
                    "click_count": integerProperty(description: "Number of clicks. Defaults to 1"),
                    "mouse_button": stringProperty(
                        description: "Mouse button to click. Defaults to left.",
                        enumValues: ["left", "right", "middle"]
                    ),
                    "include_screenshot": booleanProperty(description: "When true, attach a fresh annotated screenshot. Defaults to false."),
                ],
                required: ["app"]
            )
        ),
        ToolDefinition(
            name: "drag",
            description: "Drag from one screenshot pixel coordinate to another.",
            annotations: defaultAnnotations(),
            inputSchema: objectSchema(
                properties: [
                    "app": stringProperty(description: "App name or bundle identifier"),
                    "from_x": numberProperty(description: "Start X coordinate"),
                    "from_y": numberProperty(description: "Start Y coordinate"),
                    "to_x": numberProperty(description: "End X coordinate"),
                    "to_y": numberProperty(description: "End Y coordinate"),
                    "include_screenshot": booleanProperty(description: "When true, attach a fresh annotated screenshot. Defaults to false."),
                ],
                required: ["app", "from_x", "from_y", "to_x", "to_y"]
            )
        ),
        ToolDefinition(
            name: "get_app_state",
            description: "Return the key window accessibility tree and an annotated screenshot (numbered Set-of-Mark boxes). Call once per assistant turn before other actions on that app.",
            annotations: readOnlyAnnotations(),
            inputSchema: objectSchema(
                properties: [
                    "app": stringProperty(description: "App name or bundle identifier"),
                    "format": stringProperty(
                        description: "Tree format: text (default) or yaml.",
                        enumValues: ["text", "yaml"]
                    ),
                    "ocr": booleanProperty(description: "Run Apple Vision OCR and merge detected text. Defaults to env CAIRN_OCR_DEFAULT or false."),
                    "inline_image": booleanProperty(description: "When true, embed PNG in the tool result. When false (default), expose resources/read URI."),
                ],
                required: ["app"]
            )
        ),
        ToolDefinition(
            name: "list_apps",
            description: "List running apps and recently used apps (last 14 days) with usage hints.",
            annotations: readOnlyAnnotations(),
            inputSchema: objectSchema(properties: [:], required: [])
        ),
        ToolDefinition(
            name: "perform_secondary_action",
            description: "Invoke a secondary accessibility action from the element line (Secondary Actions: …).",
            annotations: defaultAnnotations(),
            inputSchema: objectSchema(
                properties: [
                    "app": stringProperty(description: "App name or bundle identifier"),
                    "element_index": stringProperty(description: elementIndexDescription),
                    "action": stringProperty(description: "Secondary accessibility action name"),
                    "include_screenshot": booleanProperty(description: "When true, attach a fresh annotated screenshot. Defaults to false."),
                ],
                required: ["app", "element_index", "action"]
            )
        ),
        ToolDefinition(
            name: "press_key",
            description: "Press a key or key combination (xdotool-style syntax).",
            annotations: defaultAnnotations(),
            inputSchema: objectSchema(
                properties: [
                    "app": stringProperty(description: "App name or bundle identifier"),
                    "key": stringProperty(
                        description: "Key or key combination to press",
                        examples: ["Return", "Tab", "super+c", "shift+tab"]
                    ),
                    "include_screenshot": booleanProperty(description: "When true, attach a fresh annotated screenshot. Defaults to false."),
                ],
                required: ["app", "key"]
            )
        ),
        ToolDefinition(
            name: "scroll",
            description: "Scroll an element in a direction by a number of pages.",
            annotations: defaultAnnotations(),
            inputSchema: objectSchema(
                properties: [
                    "app": stringProperty(description: "App name or bundle identifier"),
                    "direction": stringProperty(
                        description: "Scroll direction",
                        enumValues: ["up", "down", "left", "right"]
                    ),
                    "element_index": stringProperty(description: elementIndexDescription),
                    "pages": numberProperty(description: "Number of pages to scroll. Fractional values are supported. Defaults to 1"),
                    "include_screenshot": booleanProperty(description: "When true, attach a fresh annotated screenshot. Defaults to false."),
                ],
                required: ["app", "element_index", "direction"]
            )
        ),
        ToolDefinition(
            name: "set_value",
            description: "Set the value of a settable accessibility element (text fields, search boxes).",
            annotations: defaultAnnotations(),
            inputSchema: objectSchema(
                properties: [
                    "app": stringProperty(description: "App name or bundle identifier"),
                    "element_index": stringProperty(description: elementIndexDescription),
                    "value": stringProperty(description: "Value to assign"),
                    "include_screenshot": booleanProperty(description: "When true, attach a fresh annotated screenshot. Defaults to false."),
                ],
                required: ["app", "element_index", "value"]
            )
        ),
        ToolDefinition(
            name: "type_text",
            description: "Type literal text into the focused control. Click a text field or use set_value first if nothing is focused.",
            annotations: defaultAnnotations(),
            inputSchema: objectSchema(
                properties: [
                    "app": stringProperty(description: "App name or bundle identifier"),
                    "text": stringProperty(
                        description: "Literal text to type",
                        examples: ["Hello", "search query"]
                    ),
                    "include_screenshot": booleanProperty(description: "When true, attach a fresh annotated screenshot. Defaults to false."),
                ],
                required: ["app", "text"]
            )
        ),
    ]
}

private func objectSchema(properties: [String: Any], required: [String]) -> [String: Any] {
    var schema: [String: Any] = [
        "type": "object",
        "properties": properties,
        "additionalProperties": false,
    ]

    if !required.isEmpty {
        schema["required"] = required
    }

    return schema
}

private func defaultAnnotations() -> [String: Any] {
    [
        "destructiveHint": false,
        "openWorldHint": false,
    ]
}

private func readOnlyAnnotations() -> [String: Any] {
    [
        "destructiveHint": false,
        "idempotentHint": true,
        "openWorldHint": false,
        "readOnlyHint": true,
    ]
}

private func stringProperty(description: String, enumValues: [String]? = nil, examples: [String]? = nil) -> [String: Any] {
    var property: [String: Any] = [
        "type": "string",
        "description": description,
    ]

    if let enumValues {
        property["enum"] = enumValues
    }

    if let examples {
        property["examples"] = examples
    }

    return property
}

private func integerProperty(description: String) -> [String: Any] {
    [
        "type": "integer",
        "description": description,
    ]
}

private func numberProperty(description: String) -> [String: Any] {
    [
        "type": "number",
        "description": description,
    ]
}

private func booleanProperty(description: String) -> [String: Any] {
    [
        "type": "boolean",
        "description": description,
    ]
}
