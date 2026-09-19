embedded_components {
  id: "model"
  type: "model"
  data: "mesh: \"/assets/models/sidestep_airdrop.glb\"\n"
  "name: \"{{NAME}}\"\n"
  "materials {\n"
  "  name: \"default\"\n"
  "  material: \"/render/prop_materials/obstacle.material\"\n"
  "  textures {\n"
  "    sampler: \"tex0\"\n"
  "    texture: \"/assets/gfx/textures/prop.png\"\n"
  "  }\n"
  "}\n"
  "create_go_bones: false\n"
  ""
  position {
    x: 0.38
  }
}
embedded_components {
  id: "collider"
  type: "model"
  data: "mesh: \"/assets/models/sidestep_collider.glb\"\n"
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
