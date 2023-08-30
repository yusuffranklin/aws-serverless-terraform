output "endpoint_url" {
    value = "${aws_amplify_app.powerofmath_html.invoke_url}"
}