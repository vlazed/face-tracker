---@meta

---@generic T, U
---@alias Set<T, U> {[T]: U}

---@alias FlexResetters FlexName[]

---@class ClientFlexable
---@field entity Entity
---@field expressions FlexExpressions
---@field resetters FlexName[]
---@field flexCount integer
---@field nameToId {[FlexName]: integer}
---@field idToName {[integer]: FlexName}
---@field flex number[]

---@class ServerFlexable
---@field entity Entity

---@class FlexableInfo
---@field previousCount integer

---@class ClientFlexableInfo: FlexableInfo
---@field flexables ClientFlexable[]
---@field count integer

---@alias FlexName string
---@alias FlexExpression string
---@alias FlexExpressions {[FlexName]: FlexExpression}

---@class PanelState
---@field flexable Entity
---@field expressions FlexExpressions

---@class PanelProps
---@field flexable Entity

---@class PanelChildren
---@field treePanel DTreeScroller
---@field updateInterval DNumSlider
---@field arkitForm DForm
---@field expressionForm DForm
---@field presets facetracker_presetsaver
---@field connect DButton
---@field latency DLabel
---@field remove DButton

---Wrapper for `DTree_Node`
---@class TreePanel_Node: DTree_Node
---@field Icon DImage
---@field info EntityTree
---@field GetChildNodes fun(self: TreePanel_Node): TreePanel_Node[]

---Wrapper for `DTree`
---@class TreePanel: DTreeScroller
---@field ancestor TreePanel_Node
---@field GetSelectedItem fun(self: TreePanel): TreePanel_Node

---Main structure representing an entity's model tree
---@class EntityTree
---@field parent integer?
---@field entity integer
---@field children EntityTree[]

---@class Parser
---@field solve fun(self: Parser, expression: string): result: number
---@field addVariable fun(self: Parser, variableName: string, variableValue: number)
