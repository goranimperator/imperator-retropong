import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {

    enum GameState {
        case waitingToStart
        case playing
        case scored
        case gameOver
    }

    private var playerPaddle: SKSpriteNode!
    private var aiPaddle: SKSpriteNode!
    private var ball: SKSpriteNode!
    private var messageNode: SKNode!

    private var playerScoreNode: SKNode!
    private var aiScoreNode: SKNode!

    private var centerDashes: [SKSpriteNode] = []
    private var gameLayer: SKEffectNode!
    private var crtLayer: SKNode!
    private var scanlineOverlay: SKSpriteNode!
    private var flickerOverlay: SKSpriteNode!
    private var trackingBand: SKSpriteNode!
    private var noiseOverlay: SKSpriteNode!

    private var messageText: String = "CLICK TO START"
    private var gameState: GameState = .waitingToStart
    private var playerScore = 0
    private var aiScore = 0
    private var currentBallSpeed = GameConfig.initialBallSpeed
    private var lastUpdateTime: TimeInterval = 0

    private let minPaddleX = GameConfig.fieldMinX + GameConfig.paddleWidth / 2
    private let maxPaddleX = GameConfig.fieldMaxX - GameConfig.paddleWidth / 2

    override func didMove(to view: SKView) {
        backgroundColor = .black
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self

        setupGameLayer()
        setupCenterLine()
        setupScoreDisplays()
        setupPaddles()
        setupBall()
        setupWalls()
        setupGoals()
        setupMessage()
        setupCRT()
        applySkin()
    }

    private func setupGameLayer() {
        gameLayer = SKEffectNode()
        let bloom = CIFilter(name: "CIBloom")!
        bloom.setValue(6.0, forKey: "inputRadius")
        bloom.setValue(0.6, forKey: "inputIntensity")
        gameLayer.filter = bloom
        gameLayer.shouldEnableEffects = true
        addChild(gameLayer)
    }

    // MARK: - CRT effects (scanlines + flicker + VHS tracking + noise + jitter)

    private func setupCRT() {
        let w = GameConfig.sceneWidth
        let h = GameConfig.sceneHeight

        crtLayer = SKNode()
        crtLayer.zPosition = 100
        crtLayer.isUserInteractionEnabled = false
        addChild(crtLayer)

        setupScanlines(w: w, h: h)
        setupFlicker(w: w, h: h)
        setupTrackingBand(w: w, h: h)
        setupNoise(w: w, h: h)
        setupScreenJitter()
    }

    private func setupScanlines(w: CGFloat, h: CGFloat) {
        let lineH: CGFloat = 2
        let gap: CGFloat = 2
        let tex = createScanlineTexture(width: Int(w), height: Int(h), lineHeight: lineH, gap: gap)
        scanlineOverlay = SKSpriteNode(texture: tex, size: CGSize(width: w, height: h))
        scanlineOverlay.anchorPoint = CGPoint(x: 0, y: 0)
        scanlineOverlay.position = .zero
        scanlineOverlay.alpha = 0.35
        crtLayer.addChild(scanlineOverlay)
    }

    private func setupFlicker(w: CGFloat, h: CGFloat) {
        flickerOverlay = SKSpriteNode(color: NSColor(white: 0.07, alpha: 1), size: CGSize(width: w, height: h))
        flickerOverlay.anchorPoint = CGPoint(x: 0, y: 0)
        flickerOverlay.position = .zero
        flickerOverlay.alpha = 0
        flickerOverlay.blendMode = .alpha
        crtLayer.addChild(flickerOverlay)

        var actions: [SKAction] = []
        let opacities: [CGFloat] = [
            0.28, 0.35, 0.24, 0.91, 0.18, 0.84, 0.66, 0.68, 0.27, 0.85,
            0.96, 0.09, 0.20, 0.72, 0.53, 0.37, 0.71, 0.70, 0.70, 0.36, 0.24
        ]
        let step = 0.1 / Double(opacities.count)
        for o in opacities {
            actions.append(SKAction.fadeAlpha(to: o * 0.12, duration: step))
        }
        flickerOverlay.run(SKAction.repeatForever(SKAction.sequence(actions)))
    }

    private func setupTrackingBand(w: CGFloat, h: CGFloat) {
        let bandH: CGFloat = 40
        let tex = createTrackingBandTexture(width: Int(w), height: Int(bandH))
        trackingBand = SKSpriteNode(texture: tex, size: CGSize(width: w, height: bandH))
        trackingBand.anchorPoint = CGPoint(x: 0, y: 0)
        trackingBand.position = CGPoint(x: 0, y: h)
        trackingBand.alpha = 0.7
        trackingBand.blendMode = .add
        crtLayer.addChild(trackingBand)

        let moveDown = SKAction.moveTo(y: -bandH, duration: 2.5)
        let reset = SKAction.moveTo(y: h, duration: 0)
        trackingBand.run(SKAction.repeatForever(SKAction.sequence([moveDown, reset])))
    }

    private func setupNoise(w: CGFloat, h: CGFloat) {
        let noiseSize = 120
        let tex = createNoiseTexture(size: noiseSize)
        noiseOverlay = SKSpriteNode(texture: tex, size: CGSize(width: w * 1.5, height: h * 1.5))
        noiseOverlay.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        noiseOverlay.position = CGPoint(x: w / 2, y: h / 2)
        noiseOverlay.alpha = 0.06
        noiseOverlay.blendMode = .screen
        crtLayer.addChild(noiseOverlay)

        var noiseActions: [SKAction] = []
        let offsets: [(CGFloat, CGFloat)] = [
            (0, 0), (-8, 5), (5, -7), (-5, -3), (7, 4)
        ]
        for (dx, dy) in offsets {
            noiseActions.append(SKAction.move(to: CGPoint(x: w / 2 + dx, y: h / 2 + dy), duration: 0.032))
        }
        noiseOverlay.run(SKAction.repeatForever(SKAction.sequence(noiseActions)))
    }

    private func setupScreenJitter() {
        let gameContent = SKNode()
        gameContent.name = "gameContentWrapper"

        let jitterCycle = SKAction.sequence([
            SKAction.wait(forDuration: 2.0 + Double.random(in: 0...1)),
            SKAction.run { [weak self] in self?.fireGlitch() },
        ])
        run(SKAction.repeatForever(jitterCycle), withKey: "jitterLoop")
    }

    private func fireGlitch() {
        let dx = CGFloat.random(in: -4...4)
        let dur = Double.random(in: 0.06...0.15)

        let shift = SKAction.sequence([
            SKAction.moveBy(x: dx, y: CGFloat.random(in: -1...1), duration: 0.02),
            SKAction.wait(forDuration: dur),
            SKAction.move(to: .zero, duration: 0.02),
        ])

        let brighten = SKAction.sequence([
            SKAction.run { [weak self] in self?.flickerOverlay?.alpha = 0.25 },
            SKAction.wait(forDuration: dur),
            SKAction.run { [weak self] in self?.flickerOverlay?.alpha = 0.04 },
        ])

        let scanShift = SKAction.sequence([
            SKAction.run { [weak self] in self?.scanlineOverlay?.position.y = CGFloat.random(in: -2...2) },
            SKAction.wait(forDuration: dur),
            SKAction.run { [weak self] in self?.scanlineOverlay?.position.y = 0 },
        ])

        crtLayer.run(shift)
        run(brighten)
        run(scanShift)
    }

    // MARK: - CRT texture generation

    private func createScanlineTexture(width: Int, height: Int, lineHeight: CGFloat, gap: CGFloat) -> SKTexture {
        let size = CGSize(width: width, height: height)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.clear.setFill()
        NSRect(origin: .zero, size: size).fill()
        NSColor.black.setFill()
        var y: CGFloat = 0
        let stride = lineHeight + gap
        while y < CGFloat(height) {
            NSRect(x: 0, y: y, width: CGFloat(width), height: lineHeight).fill()
            y += stride
        }
        image.unlockFocus()
        return SKTexture(image: image)
    }

    private func createTrackingBandTexture(width: Int, height: Int) -> SKTexture {
        let size = CGSize(width: width, height: height)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.clear.setFill()
        NSRect(origin: .zero, size: size).fill()
        let h = CGFloat(height)
        let steps = 20
        for i in 0..<steps {
            let t = CGFloat(i) / CGFloat(steps)
            let alpha: CGFloat = sin(t * .pi) * 0.08
            NSColor(white: 1, alpha: alpha).setFill()
            let rowH = h / CGFloat(steps)
            NSRect(x: 0, y: t * h, width: CGFloat(width), height: rowH).fill()
        }
        image.unlockFocus()
        return SKTexture(image: image)
    }

    private func createNoiseTexture(size: Int) -> SKTexture {
        let sz = CGSize(width: size, height: size)
        let image = NSImage(size: sz)
        image.lockFocus()
        NSColor.black.setFill()
        NSRect(origin: .zero, size: sz).fill()
        let pixSize: CGFloat = 2
        for y in stride(from: 0, to: CGFloat(size), by: pixSize) {
            for x in stride(from: 0, to: CGFloat(size), by: pixSize) {
                let brightness = CGFloat.random(in: 0...1)
                NSColor(white: brightness, alpha: 1).setFill()
                NSRect(x: x, y: y, width: pixSize, height: pixSize).fill()
            }
        }
        image.unlockFocus()
        return SKTexture(image: image)
    }

    // MARK: - Skin

    func applySkin() {
        let color = Skin.current.color

        playerPaddle?.color = color
        aiPaddle?.color = color
        ball?.color = color

        for node in centerDashes { node.color = color }

        if let msg = messageNode { renderMessage(messageText, in: msg) }

        if let pNode = playerScoreNode { renderScore(playerScore, in: pNode) }
        if let aNode = aiScoreNode { renderScore(aiScore, in: aNode) }
    }

    // MARK: - Setup

    private func setupCenterLine() {
        let px = GameConfig.px
        let dashSize = 2 * px
        let gap = 2 * px
        let y = GameConfig.sceneHeight / 2 - px / 2
        var x = GameConfig.fieldMinX + px

        while x + dashSize <= GameConfig.fieldMaxX - px {
            let dash = SKSpriteNode(color: .white, size: CGSize(width: dashSize, height: px))
            dash.anchorPoint = CGPoint(x: 0, y: 0)
            dash.position = CGPoint(x: x, y: y)
            dash.zPosition = -1
            gameLayer.addChild(dash)
            centerDashes.append(dash)
            x += dashSize + gap
        }
    }

    private func setupScoreDisplays() {
        let scoreX = GameConfig.sceneWidth - 50
        playerScoreNode = SKNode()
        playerScoreNode.position = CGPoint(x: scoreX, y: GameConfig.sceneHeight * 0.25)
        playerScoreNode.zPosition = -1
        gameLayer.addChild(playerScoreNode)

        aiScoreNode = SKNode()
        aiScoreNode.position = CGPoint(x: scoreX, y: GameConfig.sceneHeight * 0.75)
        aiScoreNode.zPosition = -1
        gameLayer.addChild(aiScoreNode)

        renderScore(0, in: playerScoreNode)
        renderScore(0, in: aiScoreNode)
    }

    private func renderScore(_ score: Int, in container: SKNode) {
        container.removeAllChildren()
        let color = Skin.current.color
        let clamped = max(0, min(99, score))
        let tens = clamped / 10
        let ones = clamped % 10
        let sp = GameConfig.scorePixel
        let digitW = 3 * sp
        let gap = sp
        let totalW = digitW + gap + digitW
        let totalH = 5 * sp
        let startX = -totalW / 2
        let startY = -totalH / 2

        renderDigit(tens, at: CGPoint(x: startX, y: startY), color: color, in: container)
        renderDigit(ones, at: CGPoint(x: startX + digitW + gap, y: startY), color: color, in: container)
    }

    private func renderDigit(_ digit: Int, at origin: CGPoint, color: SKColor, in container: SKNode) {
        let pattern = GameConfig.digitPatterns[digit]
        let sp = GameConfig.scorePixel
        for row in 0..<5 {
            let rowBits = pattern[row]
            for col in 0..<3 {
                let bit = (rowBits >> (2 - col)) & 1
                if bit == 1 {
                    let block = SKSpriteNode(color: color, size: CGSize(width: sp, height: sp))
                    block.anchorPoint = CGPoint(x: 0, y: 0)
                    block.position = CGPoint(
                        x: origin.x + CGFloat(col) * sp,
                        y: origin.y + CGFloat(4 - row) * sp
                    )
                    block.alpha = Skin.current.dimAlpha
                    container.addChild(block)
                }
            }
        }
    }

    private func setupPaddles() {
        let paddleSize = CGSize(width: GameConfig.paddleWidth, height: GameConfig.paddleHeight)

        playerPaddle = SKSpriteNode(color: .white, size: paddleSize)
        playerPaddle.position = CGPoint(x: GameConfig.sceneWidth / 2, y: GameConfig.playerPaddleY)
        playerPaddle.physicsBody = SKPhysicsBody(rectangleOf: paddleSize)
        playerPaddle.physicsBody?.isDynamic = false
        playerPaddle.physicsBody?.categoryBitMask = GameConfig.paddleCategory
        playerPaddle.physicsBody?.friction = 0
        playerPaddle.physicsBody?.restitution = 1.0
        gameLayer.addChild(playerPaddle)

        aiPaddle = SKSpriteNode(color: .white, size: paddleSize)
        aiPaddle.position = CGPoint(x: GameConfig.sceneWidth / 2, y: GameConfig.aiPaddleY)
        aiPaddle.physicsBody = SKPhysicsBody(rectangleOf: paddleSize)
        aiPaddle.physicsBody?.isDynamic = false
        aiPaddle.physicsBody?.categoryBitMask = GameConfig.paddleCategory
        aiPaddle.physicsBody?.friction = 0
        aiPaddle.physicsBody?.restitution = 1.0
        gameLayer.addChild(aiPaddle)
    }

    private func setupBall() {
        let size = CGSize(width: GameConfig.ballSize, height: GameConfig.ballSize)
        ball = SKSpriteNode(color: .white, size: size)
        ball.position = CGPoint(x: GameConfig.sceneWidth / 2, y: GameConfig.sceneHeight / 2)

        ball.physicsBody = SKPhysicsBody(rectangleOf: size)
        ball.physicsBody?.isDynamic = true
        ball.physicsBody?.categoryBitMask = GameConfig.ballCategory
        ball.physicsBody?.contactTestBitMask = GameConfig.paddleCategory | GameConfig.goalCategory
        ball.physicsBody?.collisionBitMask = GameConfig.paddleCategory | GameConfig.wallCategory
        ball.physicsBody?.friction = 0
        ball.physicsBody?.restitution = 1.0
        ball.physicsBody?.linearDamping = 0
        ball.physicsBody?.angularDamping = 0
        ball.physicsBody?.allowsRotation = false
        gameLayer.addChild(ball)
    }

    private func setupWalls() {
        let minX = GameConfig.fieldMinX
        let maxX = GameConfig.fieldMaxX
        let minY = GameConfig.fieldMinY
        let maxY = GameConfig.fieldMaxY

        let leftWall = SKNode()
        leftWall.physicsBody = SKPhysicsBody(edgeFrom: CGPoint(x: minX, y: minY), to: CGPoint(x: minX, y: maxY))
        leftWall.physicsBody?.categoryBitMask = GameConfig.wallCategory
        leftWall.physicsBody?.friction = 0
        leftWall.physicsBody?.restitution = 1.0
        addChild(leftWall)

        let rightWall = SKNode()
        rightWall.physicsBody = SKPhysicsBody(edgeFrom: CGPoint(x: maxX, y: minY), to: CGPoint(x: maxX, y: maxY))
        rightWall.physicsBody?.categoryBitMask = GameConfig.wallCategory
        rightWall.physicsBody?.friction = 0
        rightWall.physicsBody?.restitution = 1.0
        addChild(rightWall)
    }

    private func setupGoals() {
        let bottomGoal = SKNode()
        bottomGoal.name = "bottomGoal"
        bottomGoal.physicsBody = SKPhysicsBody(edgeFrom: CGPoint(x: 0, y: -5), to: CGPoint(x: GameConfig.sceneWidth, y: -5))
        bottomGoal.physicsBody?.categoryBitMask = GameConfig.goalCategory
        bottomGoal.physicsBody?.collisionBitMask = 0
        addChild(bottomGoal)

        let topGoal = SKNode()
        topGoal.name = "topGoal"
        topGoal.physicsBody = SKPhysicsBody(edgeFrom: CGPoint(x: 0, y: GameConfig.sceneHeight + 5), to: CGPoint(x: GameConfig.sceneWidth, y: GameConfig.sceneHeight + 5))
        topGoal.physicsBody?.categoryBitMask = GameConfig.goalCategory
        topGoal.physicsBody?.collisionBitMask = 0
        addChild(topGoal)
    }

    private func setupMessage() {
        messageNode = SKNode()
        messageNode.position = CGPoint(x: GameConfig.sceneWidth / 2, y: GameConfig.sceneHeight / 2 + 30)
        gameLayer.addChild(messageNode)
        renderMessage(messageText, in: messageNode)
        startBlinking()
    }

    private func renderMessage(_ text: String, in container: SKNode) {
        container.removeAllChildren()
        let sp = GameConfig.messagePixel
        let charW = 3 * sp
        let gap = sp
        let totalW = CGFloat(text.count) * (charW + gap) - gap
        var x = -totalW / 2
        let color = Skin.current.color

        for ch in text {
            if let pattern = GameConfig.charPatterns[ch] {
                renderGlyph(pattern, at: CGPoint(x: x, y: -2.5 * sp), color: color, pixel: sp, in: container)
            } else if let digit = ch.wholeNumberValue {
                let pattern = GameConfig.digitPatterns[digit]
                renderGlyph(pattern, at: CGPoint(x: x, y: -2.5 * sp), color: color, pixel: sp, in: container)
            }
            x += charW + gap
        }
    }

    private func renderGlyph(_ pattern: [UInt8], at origin: CGPoint, color: SKColor, pixel sp: CGFloat, in container: SKNode) {
        for row in 0..<5 {
            let rowBits = pattern[row]
            for col in 0..<3 {
                let bit = (rowBits >> (2 - col)) & 1
                if bit == 1 {
                    let block = SKSpriteNode(color: color, size: CGSize(width: sp, height: sp))
                    block.anchorPoint = CGPoint(x: 0, y: 0)
                    block.position = CGPoint(
                        x: origin.x + CGFloat(col) * sp,
                        y: origin.y + CGFloat(4 - row) * sp
                    )
                    container.addChild(block)
                }
            }
        }
    }

    private func showMessage(_ text: String) {
        messageText = text
        renderMessage(text, in: messageNode)
        startBlinking()
    }

    private func startBlinking() {
        messageNode.removeAllActions()
        messageNode.isHidden = false
        messageNode.alpha = 1
        let blink = SKAction.sequence([
            SKAction.hide(),
            SKAction.wait(forDuration: 0.5),
            SKAction.unhide(),
            SKAction.wait(forDuration: 0.5),
        ])
        messageNode.run(SKAction.repeatForever(blink))
    }

    // MARK: - Input

    func handleMousePosition(_ location: CGPoint) {
        guard gameState == .playing else { return }
        let clampedX = max(minPaddleX, min(location.x, maxPaddleX))
        playerPaddle.position.x = clampedX
    }

    func handleClick(_ location: CGPoint) {
        switch gameState {
        case .waitingToStart:
            startGame()
        case .gameOver:
            resetGame()
        case .playing, .scored:
            handleMousePosition(location)
        }
    }

    // MARK: - Game flow

    private func startGame() {
        playerScore = 0
        aiScore = 0
        updateScoreDisplays()
        currentBallSpeed = GameConfig.initialBallSpeed
        messageNode.removeAllActions()
        messageNode.isHidden = true
        gameState = .playing
        launchBall()
    }

    func reset() {
        resetGame()
    }

    private func resetGame() {
        playerScore = 0
        aiScore = 0
        updateScoreDisplays()
        currentBallSpeed = GameConfig.initialBallSpeed
        ball.position = CGPoint(x: GameConfig.sceneWidth / 2, y: GameConfig.sceneHeight / 2)
        ball.physicsBody?.velocity = .zero
        playerPaddle.position.x = GameConfig.sceneWidth / 2
        aiPaddle.position.x = GameConfig.sceneWidth / 2
        showMessage("CLICK TO START")
        gameState = .waitingToStart
    }

    private func launchBall() {
        ball.position = CGPoint(x: GameConfig.sceneWidth / 2, y: GameConfig.sceneHeight / 2)
        let angle = CGFloat.random(in: .pi / 6 ... .pi / 3)
        let directionX: CGFloat = Bool.random() ? 1 : -1
        let directionY: CGFloat = Bool.random() ? 1 : -1
        let dx = sin(angle) * currentBallSpeed * directionX
        let dy = cos(angle) * currentBallSpeed * directionY
        ball.physicsBody?.velocity = CGVector(dx: dx, dy: dy)
    }

    private func updateScoreDisplays() {
        renderScore(playerScore, in: playerScoreNode)
        renderScore(aiScore, in: aiScoreNode)
    }

    // MARK: - Physics contact

    func didBegin(_ contact: SKPhysicsContact) {
        let a = contact.bodyA
        let b = contact.bodyB
        let categories = (a.categoryBitMask, b.categoryBitMask)

        if categories == (GameConfig.ballCategory, GameConfig.paddleCategory)
            || categories == (GameConfig.paddleCategory, GameConfig.ballCategory) {
            let paddle = a.categoryBitMask == GameConfig.paddleCategory ? a.node : b.node
            if let p = paddle as? SKSpriteNode { handlePaddleHit(paddle: p) }
        }

        if categories == (GameConfig.ballCategory, GameConfig.goalCategory)
            || categories == (GameConfig.goalCategory, GameConfig.ballCategory) {
            let goal = a.categoryBitMask == GameConfig.goalCategory ? a.node : b.node
            if let g = goal { handleGoal(g) }
        }
    }

    private func handlePaddleHit(paddle: SKSpriteNode) {
        currentBallSpeed = min(currentBallSpeed + GameConfig.speedIncrement, GameConfig.maxBallSpeed)

        let hitOffset = (ball.position.x - paddle.position.x) / (GameConfig.paddleWidth / 2)
        let clampedOffset = max(-1.0, min(1.0, hitOffset))

        let maxAngle: CGFloat = .pi * 5 / 12
        let bounceAngle = clampedOffset * maxAngle

        let directionY: CGFloat = paddle.position.y < GameConfig.sceneHeight / 2 ? 1 : -1
        let dx = sin(bounceAngle) * currentBallSpeed
        let dy = cos(bounceAngle) * currentBallSpeed * directionY
        ball.physicsBody?.velocity = CGVector(dx: dx, dy: dy)
    }

    private func handleGoal(_ goal: SKNode) {
        guard gameState == .playing else { return }
        gameState = .scored

        ball.physicsBody?.velocity = .zero

        if goal.name == "bottomGoal" {
            aiScore += 1
        } else {
            playerScore += 1
        }
        updateScoreDisplays()

        if playerScore >= GameConfig.winningScore || aiScore >= GameConfig.winningScore {
            let winner = playerScore >= GameConfig.winningScore ? "YOU WIN!" : "CPU WINS!"
            showMessage(winner)
            gameState = .gameOver
        } else {
            let wait = SKAction.wait(forDuration: 0.5)
            run(wait) { [weak self] in
                self?.gameState = .playing
                self?.launchBall()
            }
        }
    }

    // MARK: - Update loop

    override func update(_ currentTime: TimeInterval) {
        guard gameState == .playing else {
            lastUpdateTime = currentTime
            return
        }

        let dt = lastUpdateTime == 0 ? 0 : currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        updateAI(deltaTime: CGFloat(dt))
        normalizeSpeed()
    }

    private func updateAI(deltaTime dt: CGFloat) {
        guard dt > 0 else { return }
        let targetX = ball.position.x + CGFloat.random(in: -GameConfig.aiErrorMargin...GameConfig.aiErrorMargin)
        let diff = targetX - aiPaddle.position.x
        let maxMove = GameConfig.aiSpeed * dt
        let movement = max(-maxMove, min(maxMove, diff))
        let newX = aiPaddle.position.x + movement
        aiPaddle.position.x = max(minPaddleX, min(newX, maxPaddleX))
    }

    private func normalizeSpeed() {
        guard let velocity = ball.physicsBody?.velocity else { return }
        let speed = sqrt(velocity.dx * velocity.dx + velocity.dy * velocity.dy)
        guard speed > 0 else { return }

        var dx = velocity.dx
        var dy = velocity.dy
        let minVerticalRatio: CGFloat = 0.2
        if abs(dy) / speed < minVerticalRatio {
            let sign: CGFloat = dy >= 0 ? 1 : -1
            dy = sign * speed * minVerticalRatio
            dx = sqrt(speed * speed - dy * dy) * (dx >= 0 ? 1 : -1)
        }

        let scale = currentBallSpeed / speed
        ball.physicsBody?.velocity = CGVector(dx: dx * scale, dy: dy * scale)
    }
}
