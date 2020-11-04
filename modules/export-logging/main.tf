resource "google_pubsub_topic" "test-topic" {
  project = var.project_id
  name = "topic-${var.project_id}"
}

resource "google_pubsub_subscription" "test-subscription" {
  project = google_pubsub_topic.test-topic.project
  name  = "subscription-${var.project_id}"
  topic = google_pubsub_topic.test-topic.name

  # 7 days
  message_retention_duration = "604800s"
  retain_acked_messages      = true

  ack_deadline_seconds = 20

  expiration_policy {
    ttl = var.expiration_policy
  }
}

resource "google_project_iam_audit_config" "test-audit-log" {
  project = google_pubsub_topic.test-topic.project
  service = "allServices"
  audit_log_config {
    log_type = "ADMIN_READ"
  }
  audit_log_config {
    log_type = "DATA_READ"
  }
    audit_log_config {
    log_type = "DATA_WRITE"
  }
}

resource "google_logging_project_sink" "test-sink" {
  project = google_pubsub_topic.test-topic.project
  name = "logging-sink-pubsub-${var.project_id}"
  destination = "pubsub.googleapis.com/projects/${var.project_id}/topics/${google_pubsub_topic.test-topic.name}"
  filter = "logName:\"/logs/cloudaudit.googleapis.com\" OR resource.type=gce_instance"

  unique_writer_identity = true
}

resource "google_pubsub_topic_iam_binding" "test-log-writer" {
  project = google_logging_project_sink.test-sink.project
  topic = google_pubsub_topic.test-topic.name
  role = "roles/pubsub.publisher"

  members = [
    "${google_logging_project_sink.test-sink.writer_identity}"
  ]
}
