extends Label

var wingCount = 0

func addWingsToWingCount(wingsAmount):
	round(wingsAmount * randf_range(1, 3))
	wingCount += wingsAmount
	text = str(wingCount)
	
