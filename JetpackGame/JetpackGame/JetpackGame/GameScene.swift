//
//  testing.swift
//  JetpackGame
//
//  Created by Marfenko Mykhailo on 15/01/2024.
//

import SpriteKit
import GameplayKit
import CoreMotion

enum CollisionType: UInt32 {
    case player = 1
    case obstacle = 2
    case levelBounds = 4
    case coin = 8
}

enum PlayerState {
    case running, flying, dying
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let player = SKSpriteNode(imageNamed: "tile000")
    let scoreLabel = SKLabelNode(text: "Score: 0")

    var currentState: PlayerState = .running

    var runningTextures: [SKTexture] = []
    var flyingTextures: [SKTexture] = []
    var dyingTextures: [SKTexture] = []

    var score:Int = 0 {
        didSet { scoreLabel.text = "Score: \(score)" }
    }
    
    let allObstacles = ["Obstacle_horizontal", "Obstacle_vertical", "Obstacle1", "Obstacle2", "Obstacle3", "Obstacle4", "Obstacle_ground"]

    var isTouchingScreen = false
    var acceleration = 0
    var playerDied = false
    
    var obstacleSpeed: CGFloat = 500
    var speedIncreaseTimer: Timer?


    override func didMove(to view: SKView)
    {
        self.physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        self.physicsWorld.contactDelegate = self

        if let particles = SKEmitterNode(fileNamed: "Starfield") {
            particles.position = CGPoint(x: self.frame.size.width / 2, y: 0)
            particles.advanceSimulationTime(100)
            particles.zPosition = -1
            self.addChild(particles)
        }
        
        if let particles = SKEmitterNode(fileNamed: "Clouds") {
            particles.position = CGPoint(x: self.frame.size.width / 2, y: 0)
            particles.advanceSimulationTime(100)
            particles.zPosition = -1
            self.addChild(particles)
        }

        player.name = "player"
        player.setScale(0.5)
        player.position.x = frame.minX + 250
        player.zPosition = 1
        self.addChild(player)
        
        let colliderSize = CGSize(width: 200, height: 400)
        player.physicsBody = SKPhysicsBody(rectangleOf: colliderSize)
        
        //player.physicsBody = SKPhysicsBody (rectangleOf: player.texture!.size())
        //player.physicsBody = SKPhysicsBody(texture: player.texture!, size: player.texture!.size())
        player.physicsBody?.categoryBitMask = CollisionType.player.rawValue
        player.physicsBody?.collisionBitMask = CollisionType.obstacle.rawValue | CollisionType.levelBounds.rawValue
        player.physicsBody?.contactTestBitMask = CollisionType.obstacle.rawValue | CollisionType.coin.rawValue
        player.physicsBody?.isDynamic = true
        player.physicsBody?.allowsRotation = false
        player.physicsBody?.mass = 1
        loadTextures()
        animatePlayer()
        
        scoreLabel.position = CGPoint(x: 0, y: 0)
        scoreLabel.fontSize = 55
        scoreLabel.fontName = "Helvetica-Bold"
        scoreLabel.fontColor = UIColor.white
        scoreLabel.zPosition = 99
        scoreLabel.position = CGPoint(x: frame.minX + 125, y: self.frame.size.height / 2 - 75)
        
        score = 0
        
        self.addChild(scoreLabel)
        
        createBG()
        createMusic()
        createGround()
        
        let difficulty = getCurrentDifficulty()
        if (difficulty == "Baby dont hurt me"){
            Timer.scheduledTimer(timeInterval: 4, target: self, selector: #selector(addObstacle), userInfo: nil, repeats: true)
        } else if (difficulty == "Easy"){
            Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(addObstacle), userInfo: nil, repeats: true)
        } else if (difficulty == "Medium"){
            Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(addObstacle), userInfo: nil, repeats: true)
        }else if (difficulty == "Hard"){
            Timer.scheduledTimer(timeInterval: 1.5, target: self, selector: #selector(addObstacle), userInfo: nil, repeats: true)
        }else if (difficulty == "ULTRA HARDCORE!!!"){
            Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(addObstacle), userInfo: nil, repeats: true)
        }
        
        spawnCoins()
        speedIncreaseTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(increaseSpeed), userInfo: nil, repeats: true)
    }
    
    
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody:SKPhysicsBody
        var secondBody:SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask
        {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        }
        else
        {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if (firstBody.categoryBitMask & CollisionType.player.rawValue) != 0 && (secondBody.categoryBitMask & CollisionType.obstacle.rawValue) != 0
        {
            playerObstacleCollision(playerNode: firstBody.node as! SKSpriteNode, obstacleNode: secondBody.node as! SKSpriteNode)
        } else if (firstBody.categoryBitMask & CollisionType.player.rawValue) != 0 && (secondBody.categoryBitMask & CollisionType.coin.rawValue) != 0
        {
            playerCoinCollision(playerNode: firstBody.node as! SKSpriteNode, coinNode: secondBody.node as! SKSpriteNode)
        }
    }
    
    
    @objc func increaseSpeed() {
       obstacleSpeed *= 1.1
   }

        
    func loadTextures() {
        runningTextures = loadRunTextures()
        flyingTextures = loadFlyTextures()
        dyingTextures = loadDieTextures()
    }

    
    func loadDieTextures() -> [SKTexture] {
        return (0..<5).map { index in
            let formattedIndex = String(format: "%03d", index+100)
            return SKTexture(imageNamed: "tile\(formattedIndex)")
        }
    }
    func loadRunTextures() -> [SKTexture] {
        return (0..<15).map { index in
            let formattedIndex = String(format: "%03d", index+200)
            return SKTexture(imageNamed: "tile\(formattedIndex)")
        }
    }
    func loadFlyTextures() -> [SKTexture] {
        return (0..<15).map { index in
            let formattedIndex = String(format: "%03d", index)
            return SKTexture(imageNamed: "tile\(formattedIndex)")
        }
    }


    func createBG() {
        let bg = SKSpriteNode(imageNamed: "bg")
        bg.name="BG"
        bg.position = CGPoint(x: 0, y: 0)
        bg.zPosition = -99
        self.addChild(bg)
    }
    
    func createMusic() {
        let music = SKAudioNode(fileNamed: "bgmusic")
        addChild(music)
    }

    func createGround() {
        for position in ["bottom", "top"] {
            let ground = SKSpriteNode(imageNamed: "ground")
            ground.name = position.capitalized + "Ground"
            ground.anchorPoint = .zero
            ground.zPosition = 10

            var colliderSize = CGSize(width: 3000, height: 600)
            if position == "top" {
                ground.position = CGPoint(x: frame.minX, y: frame.maxY)
                ground.yScale = -1
                colliderSize = CGSize(width: 3000, height: 650)
            } else {
                print("\(frame.minY)   vs   \(frame.size.width/2)")
                ground.position = CGPoint(x: frame.minX, y: frame.minY)
            }

            ground.physicsBody = SKPhysicsBody(rectangleOf: colliderSize)
            ground.physicsBody!.affectedByGravity = false
            ground.physicsBody!.isDynamic = false
            ground.physicsBody!.categoryBitMask = CollisionType.levelBounds.rawValue
            ground.physicsBody!.collisionBitMask = CollisionType.player.rawValue
            
            
            self.addChild(ground)
        }
    }

    
    @objc func addObstacle () {
        if (currentState == .dying){
            return
        }
        let allObstaclesRnd = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: allObstacles) as! [String]
        
        let obstacle = SKSpriteNode(imageNamed: allObstaclesRnd[0])
        var randomPos: Int
        if allObstaclesRnd[0] == "Obstacle_ground" {
            randomPos = Int(self.frame.minY) + 400
        } else {
            let distribution = GKRandomDistribution(lowestValue: Int(-self.frame.size.height/2 + 500), highestValue: Int(self.frame.size.height/2 - 500))
            randomPos = distribution.nextInt()
        }

        let nextRandomPos = CGFloat(randomPos)
        
        obstacle.position = CGPoint(x: self.frame.size.width/2, y: nextRandomPos)
        
        self.addChild(obstacle)
        if allObstaclesRnd[0] == "Obstacle1" || allObstaclesRnd[0] == "Obstacle2" || allObstaclesRnd[0] == "Obstacle3" || allObstaclesRnd[0] == "Obstacle4" {
            let rotationDuration = 0.15
            let rotationAction = SKAction.rotate(byAngle: CGFloat.pi / 2, duration: rotationDuration)
            let repeatRotationAction = SKAction.repeatForever(rotationAction)
            obstacle.run(repeatRotationAction)
            obstacle.physicsBody = SKPhysicsBody(circleOfRadius: 50)
        } else if allObstaclesRnd[0] == "Obstacle_ground"{
            obstacle.physicsBody = SKPhysicsBody(circleOfRadius: 30)
        }
        else{
            obstacle.physicsBody = SKPhysicsBody(rectangleOf: obstacle.size)
        }
        
        
        obstacle.physicsBody?.categoryBitMask = CollisionType.obstacle.rawValue
        obstacle.physicsBody?.contactTestBitMask = CollisionType.player.rawValue
        obstacle.physicsBody?.collisionBitMask = 0
        obstacle.physicsBody?.isDynamic = false
        
        let moveDistance = self.frame.size.width + obstacle.size.width
        let moveDuration = TimeInterval(moveDistance / obstacleSpeed)
        let moveLeft = SKAction.moveBy(x: -moveDistance, y: 0, duration: moveDuration)
        let remove = SKAction.removeFromParent()

        obstacle.run(SKAction.sequence([moveLeft, remove]))
        score += 1
    }

    func addCoin() {
        if (currentState == .dying){
            return
        }
        let coin = SKSpriteNode(imageNamed: "coin000")
        coin.name = "Coin"
        coin.zPosition = 20.0
        coin.setScale(0.6)
        let randomPos = GKRandomDistribution(lowestValue: Int(-self.frame.size.height/2 + 500), highestValue: Int(self.frame.size.height/2 - 500))
        let nextRandomPos = CGFloat(randomPos.nextInt())
        coin.position = CGPoint(x: self.frame.size.width/2, y: nextRandomPos)
        self.addChild(coin)
        coin.run(.sequence([.wait(forDuration: 15.0), .removeFromParent()]))

        var textures: [SKTexture] = []
        for i in 0...5 {
            textures.append(SKTexture (imageNamed: "coin00\(i)"))
        }

        let moveDistance = self.frame.size.width + coin.size.width
        let moveDuration = TimeInterval(moveDistance / obstacleSpeed)
        let moveLeft = SKAction.moveBy(x: -moveDistance, y: 0, duration: moveDuration)
        let remove = SKAction.removeFromParent()
        let amplitude: CGFloat = 50.0
        let frequency: TimeInterval = 0.5

        coin.physicsBody = SKPhysicsBody(circleOfRadius: 40)
        coin.physicsBody?.categoryBitMask = CollisionType.coin.rawValue
        coin.physicsBody?.contactTestBitMask = CollisionType.player.rawValue
        coin.physicsBody?.collisionBitMask = 0
        coin.physicsBody?.isDynamic = false
        
        let sineWaveAction = SKAction.customAction(withDuration: moveDuration) { node, elapsedTime in
            let percentage = elapsedTime / CGFloat(moveDuration)
            let sineValue = sin(percentage * CGFloat.pi * 2.0 / CGFloat(frequency)) * amplitude
            node.position.y = nextRandomPos + sineValue
        }

        coin.run(SKAction.sequence([SKAction.group([sineWaveAction, moveLeft]), remove]))
        coin.run(.repeatForever(.animate(with: textures, timePerFrame: 0.05)))
    }

    func spawnCoins () {
        let random = CGFloat.random(in: 2.5...6.0)
        run(.repeatForever(.sequence([.wait(forDuration: TimeInterval(random)),.run { [weak self] in self?.addCoin() } ])))
    }
    
    
    func playerObstacleCollision (playerNode:SKSpriteNode, obstacleNode:SKSpriteNode) {
        let explosion = SKEmitterNode(fileNamed: "Explosion")!
        explosion.position = obstacleNode.position
        self.addChild(explosion)
        
        self.run(SKAction.playSoundFileNamed("explosion.mp3", waitForCompletion: false))
        
        playerDied = true
        
        let wait = SKAction.wait(forDuration: 1.0)
        let run = SKAction.run {
            playerNode.removeFromParent()
            let transition = SKTransition.flipHorizontal(withDuration: 0.5)
            if let gameScene = MainMenu(fileNamed: "MainMenu") {
                gameScene.scaleMode = .aspectFill
                self.view?.presentScene(gameScene, transition: transition)
            }
        }
        let sequence = SKAction.sequence([wait, run])
        self.run(sequence)
    
        obstacleNode.removeFromParent()
        
        self.run(SKAction.wait(forDuration: 2)) {
            explosion.removeFromParent()
        }
    }

    func playerCoinCollision (playerNode:SKSpriteNode, coinNode:SKSpriteNode) {
        let effect = SKEmitterNode(fileNamed: "CoinCollect")!
        effect.position = coinNode.position
        self.addChild(effect)
        
        self.run(SKAction.playSoundFileNamed("coinSound.mp3", waitForCompletion: false))
        
        coinNode.removeFromParent()
        
        self.run(SKAction.wait(forDuration: 2)) {
            effect.removeFromParent()
        }
        score += 5
    }


    func getCurrentDifficulty() -> String {
        let userDefaults = UserDefaults.standard
        let currentDifficulty = userDefaults.string(forKey: "currentDifficulty") ?? "Medium"
        return currentDifficulty
    }
    
    
    func animatePlayer() {
        var textures: [SKTexture] = []
        var actionKey: String = ""

        switch currentState {
        case .running:
            textures = runningTextures
            actionKey = "runningAnimation"
        case .flying:
            textures = flyingTextures
            actionKey = "flyingAnimation"
        case .dying:
            textures = dyingTextures
            actionKey = "dyingAnimation"
        }

        if player.action(forKey: actionKey) == nil {
            player.removeAllActions()

            var timePerFrame = 0.1
            if actionKey == "runningAnimation"{
                timePerFrame = 0.035
            }
            else if actionKey == "dyingAnimation"{
                timePerFrame = 0.2
            }
            let animationAction = SKAction.animate(with: textures, timePerFrame: timePerFrame)
            player.run(SKAction.repeatForever(animationAction), withKey: actionKey)
        }
    }

    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTouchingScreen = true
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTouchingScreen = false
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        let minY = Int(self.frame.minY) + 550

        if isTouchingScreen && currentState != .dying
        {
            let upwardForce = CGVector(dx: 0, dy: 3333)
            player.physicsBody?.applyForce(upwardForce)
        }

        if playerDied {
            currentState = .dying
        } else if Int(player.position.y) <= minY {
            currentState = .running
        } else {
            currentState = .flying
        }
        animatePlayer()
    }
}
