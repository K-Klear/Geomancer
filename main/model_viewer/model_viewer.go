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
embedded_components {
  id: "background"
  type: "sprite"
  data: "default_animation: \"white_pixel\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "size {\n"
  "  x: 400.0\n"
  "  y: 507.0\n"
  "}\n"
  "size_mode: SIZE_MODE_MANUAL\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/assets/gfx/UI.atlas\"\n"
  "}\n"
  ""
  position {
    x: 634.0
    y: 293.5
  }
}
