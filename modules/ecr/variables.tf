variable "ecr_name"     { type = string }
variable "scan_on_push" { type = bool,   default = true }
variable "tags"         { type = map(string), default = {} }
