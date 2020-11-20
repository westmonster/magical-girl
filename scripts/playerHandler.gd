extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
var playerClass = ""
var projectile
var speed	= 10
var health	= 3000
var potions	= 0
var whtKeys	= 0
var redKeys	= 0
var ylwKeys	= 0
var bluKeys	= 0
var score	= 0

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

func save():
	pass

func storeValues(body):
	playerClass = body.playerClass
	health		= body.health
	potions		= body.potions
	whtKeys		= body.whtKeys
	redKeys		= body.redKeys
	ylwKeys		= body.ylwKeys
	bluKeys		= body.bluKeys
	score		= body.score

func applyValues(body):
	body.playerClass= playerClass
	body.projectile = projectile
	body.BaseWalkVelocity = speed
	body.health		= health
	body.potions	= potions
	body.whtKeys	= whtKeys
	body.redKeys	= redKeys
	body.ylwKeys	= ylwKeys
	body.bluKeys	= bluKeys
	body.score		= score
