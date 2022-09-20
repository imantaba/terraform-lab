resource "kubernetes_deployment_v1" "frontend" {
  metadata {
    name = "frontend"
    namespace = "tf-ns"
    labels = {
      name = "frontend"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        name = "webapp"
      }
    }

    template {
      metadata {
        labels = {
          name = "webapp"
        }
      }

      spec {
        container {
          image = "nginx:latest"
          name  = "simple-webapp"
          port {
            container_port = "80"
          }

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
        }
      }
    }
  }
}


resource "kubernetes_service_v1" "webapp-service" {
  metadata {
    name = "webapp-service"
    namespace = "tf-ns"
  }
  spec {
    selector = {
      name = "webapp"
    }
    session_affinity = "ClientIP"
    port {
      port        = 8080
      target_port = 80
    }

  }
}


resource "kubernetes_ingress_v1" "ingress_tf" {
  metadata {
    name = "terraform-ingress"
    namespace = "tf-ns"
    annotations = {
      "cert-manager.io/cluster-issuer": "letsencrypt"
    }
  }
  spec {
    ingress_class_name = "nginx"
    rule {
      host = "terraform.pubnito.com"
      http {
        path {
          path = "/"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = "webapp-service"
              port {
                number = 8080
              }
            }
          }
        }
      }
    }
    tls {
      hosts = ["terraform.pubnito.com"]
      secret_name = "terraform-pubnito-com-cert"
    }
  }
}