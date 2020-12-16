# Define outputs
output "topic_name" {
  value = "${google_pubsub_topic.test-topic.name}"
}

output "subscription_name" {
  value = "${google_pubsub_subscription.test-subscription.name}"
}
