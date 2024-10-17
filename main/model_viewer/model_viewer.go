components {
  id: "model_viewer"
  component: "/main/model_viewer/model_viewer.script"
}
components {
  id: "model_viewer1"
  component: "/main/model_viewer/model_viewer.gui"
}
embedded_components {
  id: "create_mesh"
  type: "factory"
  data: "prototype: \"/main/model_viewer/mesh.go\"\n"
  ""
}
embedded_components {
  id: "create_transform"
  type: "factory"
  data: "prototype: \"/main/model_viewer/transform.go\"\n"
  ""
}
