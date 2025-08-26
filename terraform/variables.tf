variable "block_acls" {
  description = "Controls whether to block public ACLs (Access Control Lists)"
  type        = bool
  default     = false // Allow ACLs for public access (set true for restricted environments)
}

variable "block_public_policy" {
  description = "Controls whether to block bucket policies that allow public access"
  type        = bool
  default     = false // Allow public policies (set true to lock down)
}

variable "resume_bucket_name" {
  description = "The name of the S3 bucket for the static resume website"
  type        = string
}

variable "region" {
  description = "The AWS region to deploy resources into"
  type        = string
  default     = "var.region" # or whichever region you're using
}

variable "allow_public_access" {
  description = "Whether to allow public read access to the S3 bucket"
  type        = bool
  default     = true // Set to false in production if needed
}

variable "log_bucket_public_block_enabled" {
  description = "Toggle full lock on the logging bucket (should almost always be true)"
  type        = bool
  default     = true
}




