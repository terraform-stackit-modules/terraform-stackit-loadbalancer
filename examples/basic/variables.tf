variable "project_id" {
  description = "The STACKIT project ID."
  type        = string
}

variable "image_id" {
  description = "The image ID used for the backend server boot volume. Defaults to a known-valid Ubuntu image in eu01."
  type        = string
  default     = "012d2f5b-ee00-4700-9bea-cdabf0e1bfa8"
}

variable "machine_type" {
  description = "The machine type (flavor) of the backend server."
  type        = string
  default     = "g1a.1d"
}
