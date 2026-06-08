embedded_components {
  id: "model"
  type: "model"
  data: "mesh: \"/assets/models/sidestep.dae\"\n"
  "name: \"{{NAME}}\"\n"
  "materials {\n"
  "  name: \"default\"\n"
  "  material: \"/render/prop_materials/prop.material\"\n"
  "  textures {\n"
  "    sampler: \"tex0\"\n"
  "    texture: \"/assets/gfx/textures/prop.png\"\n"
  "  }\n"
  "}\n"
  "create_go_bones: false\n"
  ""
  rotation {
    x: 0.70710677
    w: 0.70710677
  }
}
embedded_components {
  id: "collider"
  type: "model"
  data: "mesh: \"/assets/models/sidestep_collider.dae\"\n"
  "name: \"{{NAME}}\"\n"
  "materials {\n"
  "  name: \"default\"\n"
  "  material: \"/render/prop_materials/collider.material\"\n"
  "  textures {\n"
  "    sampler: \"tex0\"\n"
  "    texture: \"/assets/gfx/textures/collider.png\"\n"
  "  }\n"
  "}\n"
  "create_go_bones: false\n"
  ""
}
