extends Node

@export var sphereScale := 0.1
@export var lava:MeshInstance3D
@export var materialId:int

@onready var anim:AnimationPlayer = %AnimationPlayer
@onready var sphere1:Node3D = %Sphere1
@onready var sphere2:Node3D = %Sphere2
@onready var sphere3:Node3D = %Sphere3
@onready var sphereTop:Node3D = %SphereTop
@onready var sphereBottom:Node3D = %SphereBottom

var material:ShaderMaterial

func _ready() -> void:
	material = lava.get_active_material(materialId)
	anim.play("LavaLampIdle")
	sphere1.set_visible(false)
	sphere2.set_visible(false)
	sphere3.set_visible(false)
	sphereTop.set_visible(false)
	sphereBottom.set_visible(false)


func _process(_delta: float) -> void:
	var positions: Array[Vector4] = [Vector4.ZERO, Vector4.ZERO, Vector4.ZERO, Vector4.ZERO, Vector4.ZERO]
	var buffer := Vector3.ZERO
	
	# TODO: The spheres could be stored in a array, just like the shader
	var localSphereScale := sphere1.scale.x /2.0
	buffer = sphere1.position
	positions[0] = Vector4(buffer.x, buffer.y, buffer.z, localSphereScale)
	
	localSphereScale = sphere2.scale.x /2.0
	buffer = sphere2.position
	positions[1] = Vector4(buffer.x, buffer.y, buffer.z, localSphereScale)
	
	localSphereScale = sphere3.scale.x /2.0
	buffer = sphere3.position
	positions[2] = Vector4(buffer.x, buffer.y, buffer.z, localSphereScale)
	
	localSphereScale = sphereTop.scale.x /2.0
	buffer = sphereTop.position
	positions[3] = Vector4(buffer.x, buffer.y, buffer.z, localSphereScale)
	
	localSphereScale = sphereBottom.scale.x /2.0
	buffer = sphereBottom.position
	positions[4] = Vector4(buffer.x, buffer.y, buffer.z, localSphereScale)
	
	material.set_shader_parameter("sphereList", positions)
