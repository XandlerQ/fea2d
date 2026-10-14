extends RefCounted
class_name VectorConverter

static func convert_vector_3_2(vector: Vector3) -> Vector2:
	var rVector: Vector2 = Vector2.ZERO
	rVector.x = vector.x
	rVector.y = vector.z
	return rVector

static func convert_vector_2_3(vector: Vector2) -> Vector3:
	var rVector: Vector3 = Vector3.ZERO
	rVector.x = vector.x
	rVector.z = vector.y
	return rVector;
