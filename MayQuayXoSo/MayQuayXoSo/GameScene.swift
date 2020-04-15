//
//  GameScene.swift
//  MayQuayXoSo
//
//  Created by Nguyen Nam on 3/31/20.
//  Copyright © 2020 Nguyen Nam. All rights reserved.
//

import SpriteKit
import GameplayKit

struct SizeConfig {
    
    let sceneSize: CGSize
    let ballWidth: CGFloat
    
    // MARK: - private contants
    private let dummyTopRatio: CGFloat = (800 / 141)
    private let boxImgRatio: CGFloat = (800 / 790)
    private let bodyImgRatio: CGFloat = (800 / 225)
    private let footerImgRatio: CGFloat = (800 / 247)
    private let sceneRatio = 800 / 1261
    private let ballRatio: CGFloat = 800 / 120
    
    // MARK: - get properties
    var boxHeight: CGFloat {
        return sceneSize.width / boxImgRatio
    }
    
    var _ballWidth: CGFloat {
        return sceneSize.width / ballRatio
    }
    
    var dummyTopHeight: CGFloat {
        return sceneSize.width / dummyTopRatio
    }
    
    var edgeWeight: CGFloat {
        return sceneSize.width / (800 / 16)
    }
    
    var bodyBackgroundHeight: CGFloat {
        return sceneSize.width / bodyImgRatio
    }
    
    var footerBackgroundHeight: CGFloat {
        return sceneSize.width / footerImgRatio
    }
    
    var holeWidth: CGFloat {
        return sceneSize.width / (800 / (ballWidth + 5))
    }
    
}

class BallModel {
    
    let spriteNode: SKSpriteNode
    let texture: String
    let index: Int
    
    init(spriteNode: SKSpriteNode, texture: String, index: Int) {
        self.spriteNode = spriteNode
        self.texture = texture
        self.index = index
    }
    
}

class GameScene: SKScene {
    
    // MARK: - Public properties
    
    /// Anim step 1
    var boxAnimDuration: TimeInterval = 2.0
    var ballWidth: CGFloat = 120
    
    /// Anim step 2
    var rotateLockAnimDuration: TimeInterval = 1.0
    
    /// Anim step 3
    var moveBallAnimDuration: TimeInterval = 1
    
    /// Anim step 4
    var shakeAnimDuration: TimeInterval = 1
    
    /// Anim step 5
    var openBallAnimDuration: TimeInterval = 1
    
    /// Anim step 6
    var moveCoinAnimDuration: TimeInterval = 1
    
    // MARK: - Private properties
    private var listBall: [BallModel] = []
    private var displayLink: CADisplayLink?
    private var decreaseStartTime: Date!
    private var midX: CGFloat = 0.0
    private var midY: CGFloat = 0.0
    private var boxEdge: [SKSpriteNode] = []
    private var sizeConfig: SizeConfig!
    private var isOpenningBox: Bool = false
    
    private var lockNode: SKSpriteNode!
    
    private var ballResult: BallModel?
    private var ballSpriteResultOldPosition: CGPoint?
    private var ballSpriteResultIsIdle: Bool = false
    private var timeGotBallSpriteResult: TimeInterval = 0
    
    private var starNodes: [SKSpriteNode] = []
    private var spaceEdge: SKSpriteNode!
    
    // x,y anchor == (0,1)
    override func didMove(to view: SKView) {
        backgroundColor = .white
        sizeConfig = SizeConfig(sceneSize: self.size, ballWidth: ballWidth)
        midX = size.width / 2
        midY = size.height / 2
        
        setuoBoxBackground()
        setupBoxPhysical()
        setupBodyBackground()
        setupFooterBackground()
        setupLockNode()
        
        createBall()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2.0) {
            self.impulseBalls()
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        if closeDoorToGetOneBall(at: currentTime) && !ballSpriteResultIsIdle {
            guard currentTime != self.timeGotBallSpriteResult else { return }
            if self.waitBallOutOfBoxAndIdle(ball: self.ballResult) {
                
                self.animationBallResultAnimate()
            }
        }
    }
    
    // MARK: - Public function
    public func impulseBalls() {
        self.initDisplayLink()
        self.listBall.forEach { (ball) in
            ball.spriteNode.physicsBody?.applyImpulse(CGVector(dx: size.width,
                                                    dy: sizeConfig.boxHeight))
        }
    }
    
    // MARK: - Private functions
    private func setuoBoxBackground() {
        let boxBackground = SKSpriteNode(imageNamed: "box")
        boxBackground.size = CGSize(width: size.width, height: sizeConfig.boxHeight)
        boxBackground.position = CGPoint(x: midX, y: -sizeConfig.boxHeight / 2)
        boxBackground.zPosition = 0
        addChild(boxBackground)
    }
    
    private func setupBoxPhysical() {
        let edgeWeight = sizeConfig.edgeWeight
        let edgeHeight = sizeConfig.boxHeight - sizeConfig.dummyTopHeight
        
        let topBottomEdgeSize = CGSize(width: size.width, height: edgeWeight)
        let leftRightEdgeSize = CGSize(width: edgeWeight, height: edgeHeight)
        // draw all edge of box
        let topEdge = SKSpriteNode(color: .clear, size: topBottomEdgeSize)
        topEdge.position = CGPoint(x: midX, y: -(sizeConfig.dummyTopHeight + edgeWeight / 2))
        topEdge.physicsBody = SKPhysicsBody(rectangleOf: topEdge.size)
        addChild(topEdge)
        
        let leftEdge = SKSpriteNode(color: .clear, size: leftRightEdgeSize)
        leftEdge.position = CGPoint(x: edgeWeight / 2,
                                    y: -(sizeConfig.dummyTopHeight + edgeHeight / 2))
        leftEdge.physicsBody = SKPhysicsBody(rectangleOf: leftEdge.size)
        addChild(leftEdge)
        
        let rightEdge = SKSpriteNode(color: .clear, size: leftRightEdgeSize)
        rightEdge.position = CGPoint(x: size.width - edgeWeight / 2,
                                     y: -(sizeConfig.dummyTopHeight + edgeHeight / 2))
        rightEdge.physicsBody = SKPhysicsBody(rectangleOf: rightEdge.size)
        addChild(rightEdge)
        
        let bottomEdge = SKSpriteNode(color: .clear, size: topBottomEdgeSize)
        bottomEdge.position = CGPoint(x: midX, y: -(sizeConfig.boxHeight - edgeWeight / 2))
        bottomEdge.physicsBody = SKPhysicsBody(rectangleOf: bottomEdge.size)
        addChild(bottomEdge)
        
        // corner edgies
        let curve: CGFloat = 145
        let cornerSize = CGSize(width: size.width / (800 / 190), height: edgeWeight)
        
        let leftTopCorner = SKSpriteNode(color: .clear, size: cornerSize)
        leftTopCorner.position = CGPoint(x: curve / 2,
                                         y: -(sizeConfig.dummyTopHeight + (cornerSize.width / 2 - 40.0) + edgeWeight))
        leftTopCorner.zRotation = .pi / 4
        leftTopCorner.physicsBody = SKPhysicsBody(rectangleOf: leftTopCorner.size)
        addChild(leftTopCorner)
        
        let rightTopCorner = SKSpriteNode(color: .clear, size: cornerSize)
        rightTopCorner.position = CGPoint(x: size.width - (curve / 2),
                                          y: -(sizeConfig.dummyTopHeight + (cornerSize.width / 2 - 40.0) + edgeWeight))
        rightTopCorner.zRotation = -.pi / 4
        rightTopCorner.physicsBody = SKPhysicsBody(rectangleOf: rightTopCorner.size)
        addChild(rightTopCorner)
        
        let leftBottomCorner = SKSpriteNode(color: .clear, size: cornerSize)
        leftBottomCorner.position = CGPoint(x: curve / 2,
                                            y: -(sizeConfig.boxHeight - edgeWeight / 2) + (cornerSize.width / 2 - 30))
        leftBottomCorner.physicsBody = SKPhysicsBody(rectangleOf: leftBottomCorner.size)
        leftBottomCorner.zRotation = -.pi / 4
        addChild(leftBottomCorner)
        
        let rightBottomCorner = SKSpriteNode(color: .clear, size: cornerSize)
        rightBottomCorner.position = CGPoint(x: size.width - (curve / 2),
                                             y: -(sizeConfig.boxHeight - edgeWeight / 2) + (cornerSize.width / 2 - 30))
        rightBottomCorner.zRotation = .pi / 4
        rightBottomCorner.physicsBody = SKPhysicsBody(rectangleOf: rightBottomCorner.size)
        addChild(rightBottomCorner)
        
        boxEdge = [leftEdge, topEdge, rightEdge, bottomEdge,
                   leftTopCorner, rightTopCorner, leftBottomCorner, rightBottomCorner]
        boxEdge.forEach({ self.setEdgePhysicsBody($0.physicsBody) })
    }
    
    private func setupBodyBackground() {
        let holeWidth = sizeConfig.holeWidth
        let midBodyBackground = sizeConfig.boxHeight + sizeConfig.bodyBackgroundHeight / 2
        let edgeWidth = sizeConfig.edgeWeight
        
        let bodyBackground = SKSpriteNode(imageNamed: "body")
        bodyBackground.size = CGSize(width: size.width, height: sizeConfig.bodyBackgroundHeight)
        bodyBackground.position = CGPoint(x: midX, y: -midBodyBackground)
        bodyBackground.zPosition = 0.7
        addChild(bodyBackground)
        
        // create 2 node to make pipe for ball go out
        let edgeHeight = sizeConfig.bodyBackgroundHeight + sizeConfig.footerBackgroundHeight
        
        let edgeSize = CGSize(width: edgeWidth, height: edgeHeight)
        let leftEdge = SKSpriteNode(color: .clear, size: edgeSize)
        leftEdge.position = CGPoint(x: midX - holeWidth / 2 - sizeConfig.edgeWeight / 2,
                                    y: -(sizeConfig.boxHeight + edgeSize.height / 2))
        leftEdge.physicsBody = SKPhysicsBody(rectangleOf: leftEdge.size)
        setEdgePhysicsBody(leftEdge.physicsBody, restitution: 0.1)
        addChild(leftEdge)
        
        let rightEdge = SKSpriteNode(color: .clear, size: edgeSize)
        rightEdge.position = CGPoint(x: midX + holeWidth / 2 + sizeConfig.edgeWeight / 2,
                                     y: -(sizeConfig.boxHeight + edgeSize.height / 2))
        rightEdge.physicsBody = SKPhysicsBody(rectangleOf: rightEdge.size)
        setEdgePhysicsBody(rightEdge.physicsBody, restitution: 0.1)
        addChild(rightEdge)
    }
    
    private func setupFooterBackground() {
        let footerBackground = SKSpriteNode(imageNamed: "footer")
        footerBackground.size = CGSize(width: size.width, height: sizeConfig.footerBackgroundHeight)
        footerBackground.position = CGPoint(x: midX,
                                            y: -(sizeConfig.boxHeight
                                                + sizeConfig.bodyBackgroundHeight
                                                + sizeConfig.footerBackgroundHeight / 2))
        addChild(footerBackground)
        
        let footerBottomEdge = SKSpriteNode(color: .clear,
                                            size: CGSize(width: sizeConfig.holeWidth, height: sizeConfig.edgeWeight))
        footerBottomEdge.position = CGPoint(x: midX, y: -(size.height - sizeConfig.edgeWeight / 2))
        footerBottomEdge.physicsBody = SKPhysicsBody(rectangleOf: footerBottomEdge.size)
        footerBottomEdge.physicsBody?.isDynamic = false
        addChild(footerBottomEdge)
    }
    
    private func setupLockNode() {
        let bottomBody = sizeConfig.boxHeight + sizeConfig.bodyBackgroundHeight
        let paddingBottom = sizeConfig.edgeWeight + size.width / (800 / 4)
        lockNode = SKSpriteNode(imageNamed: "lock")
        lockNode.size = CGSize(width: size.width / (800 / 158),
                               height: size.width / (800 / 140))
        lockNode.position = CGPoint(x: midX,
                                    y: -(bottomBody - paddingBottom - lockNode.size.height / 2))
        lockNode.zPosition = 1
        addChild(lockNode)
    }
    
    private func setEdgePhysicsBody(_  edge: SKPhysicsBody?, restitution: CGFloat = 1) {
        guard let edge = edge else { return }
        edge.isDynamic = false
        edge.friction = 0
        edge.restitution = restitution
        edge.categoryBitMask = 1
        edge.collisionBitMask = 2
        edge.fieldBitMask = 0
        edge.contactTestBitMask = 2
    }
    
    private func createBall() {
        for _ in 0..<10 {
            let ballWidth = sizeConfig._ballWidth
            let ballRan = Int.random(in: 1...4)
            let textureName = "ball_\(ballRan)"
            let ballIndex = listBall.count
            
            let ballNode = SKSpriteNode(imageNamed: textureName)
            ballNode.name = "ball_\(ballIndex)"
            ballNode.size = CGSize(width: ballWidth, height: ballWidth)
            ballNode.position = CGPoint(x: CGFloat.random(in: ballWidth..<size.width - ballWidth),
                                    y: -(sizeConfig.boxHeight - sizeConfig.edgeWeight) + ballWidth)
            
            ballNode.physicsBody = SKPhysicsBody(circleOfRadius: ballNode.size.width / 2)
            ballNode.physicsBody?.restitution = 1
            ballNode.zPosition = 0.5
            addChild(ballNode)
            
            let ball = BallModel(spriteNode: ballNode, texture: textureName, index: ballIndex)
            listBall.append(ball)
        }
    }
    
    private func initDisplayLink() {
        decreaseStartTime = Date()
        displayLink = CADisplayLink(target: self, selector: #selector(handleAnimationTime))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    private func descreaseDetitutionTo(value: CGFloat) {
        self.listBall.forEach { (ball) in
            ball.spriteNode.physicsBody?.restitution = value
        }
    }
    
    private func openDoorToGetBall() {
        rotateLockNodeAnimate()
        
        // make hole for ball out of box
        // create 2 bottom edge with space in middle
        // then disable physical of bottom edge
        let edgeHeight = sizeConfig.edgeWeight
        let holeWidth = sizeConfig.holeWidth
        let edgeWidth = midX - holeWidth / 2
        
        let bottomEdge1 = SKSpriteNode(color: .clear, size: CGSize(width: edgeWidth, height: edgeHeight))
        bottomEdge1.position = CGPoint(x: (midX - holeWidth / 2) / 2,
                                       y: -(sizeConfig.boxHeight - edgeHeight / 2))
        bottomEdge1.physicsBody = SKPhysicsBody(rectangleOf: bottomEdge1.size)
        setEdgePhysicsBody(bottomEdge1.physicsBody)
        addChild(bottomEdge1)
        
        let bottomEdge2 = SKSpriteNode(color: .clear, size: CGSize(width: edgeWidth, height: edgeHeight))
        bottomEdge2.position = CGPoint(x: midX + holeWidth / 2 + edgeWidth / 2,
                                       y: -(sizeConfig.boxHeight - edgeHeight / 2))
        bottomEdge2.physicsBody = SKPhysicsBody(rectangleOf: bottomEdge2.size)
        setEdgePhysicsBody(bottomEdge2.physicsBody)
        addChild(bottomEdge2)
        
        // create node to fixbug ball disply over box
        spaceEdge = SKSpriteNode(color: #colorLiteral(red: 0.1336817443, green: 0.09179023653, blue: 0.07689016312, alpha: 1), size: CGSize(width: sizeConfig.holeWidth, height: sizeConfig.edgeWeight))
        spaceEdge.position = CGPoint(x: midX, y: -(sizeConfig.boxHeight - edgeHeight / 2))
        spaceEdge.zPosition = 1
        addChild(spaceEdge)
        
        // get bottom edge to disable physics
        let bottomIndex = 3
        boxEdge[bottomIndex].physicsBody = nil
        
        isOpenningBox = true 
    }
    
    /// Close door to get one ball
    /// - Returns: ball out of box
    private func closeDoorToGetOneBall(at time: TimeInterval) -> Bool {
        if ballResult != nil {
            return true
        }
        if isOpenningBox {
            // get the ball went out of box
            let ballFilter = listBall.filter({ (ball) -> Bool in
                let topY = -ball.spriteNode.position.y - ball.spriteNode.size.height / 2
                if topY > sizeConfig.boxHeight {
                    return true
                }
                return false
            })
            if ballFilter.count > 0 {
                // ball went out of box so close hole
                let bottomIndex = 3
                boxEdge[bottomIndex].physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: size.width, height: sizeConfig.edgeWeight))
                setEdgePhysicsBody(boxEdge[bottomIndex].physicsBody, restitution: 0)
                isOpenningBox = false
                // assign to global variable
                ballResult = ballFilter.first
                ballSpriteResultOldPosition = ballResult?.spriteNode.position
                timeGotBallSpriteResult = time
                return true
            }
        }
        return false
    }
    
    private func waitBallOutOfBoxAndIdle(ball: BallModel?) -> Bool {
        guard let ballResultOldPosition = self.ballSpriteResultOldPosition,
            ballResultOldPosition == ball?.spriteNode.position else {
                self.ballSpriteResultOldPosition = ball?.spriteNode.position
                return false
        }
        ballSpriteResultIsIdle = true
        return true
    }
    
    // MARK: - Animation functions
    private func rotateLockNodeAnimate() {
        let action = SKAction.rotate(toAngle: .pi / 2, duration: rotateLockAnimDuration)
        lockNode.run(action)
    }
    
    private func animationBallResultAnimate() {
        guard let ballResult = self.ballResult else { return }
        ballResult.spriteNode.zPosition = 1
        ballResult.spriteNode.physicsBody = nil
        let ballScaleSize = CGSize(width: size.width / (800 / 400), height: size.width / (800 / 395))
        
        let moveAction = SKAction.moveBy(x: 0, y: midY - ballScaleSize.height / 2, duration: moveBallAnimDuration)
        let scaleAction = SKAction.scale(to: ballScaleSize, duration: moveBallAnimDuration)
        
        let rotateAction = SKAction.rotate(toAngle: 0, duration: moveBallAnimDuration)
        
        removeNodesDontNeed()
        // chain animation here
        ballResult.spriteNode.run(rotateAction)
        ballResult.spriteNode.run(scaleAction)
        ballResult.spriteNode.run(moveAction) { [weak ballResult, weak self] in
            guard let `self` = self, let ballResult = ballResult else { return }
            self.shakeAnimation(ball: ballResult, completion: { [weak self] in
                self?.openHalfOfBallResult(completion: {  [weak self] bodyBall in
                    self?.showCoinAndMoveToCenter()
                    bodyBall.run(SKAction.fadeOut(withDuration: self?.moveCoinAnimDuration ?? 1)) {
                        bodyBall.removeFromParent()
                    }
                })
            })
        }
    }
    
    private func removeNodesDontNeed() {
        let fadeOutAction = SKAction.fadeOut(withDuration: moveBallAnimDuration)
        spaceEdge.color = .clear
        self.children.forEach({ node in
            if node != ballResult?.spriteNode {
                node.run(fadeOutAction) {
                    node.removeFromParent()
                }
            }
        })
    }
    
    private func shakeAnimation(ball: BallModel, completion: @escaping () -> Void) {
        let degree = CGFloat.pi / 18 // 10°
        
        let shakeAction1 = SKAction.rotate(toAngle: degree, duration: shakeAnimDuration / 4)
        let shakeAction0 = SKAction.rotate(toAngle: 0, duration: shakeAnimDuration / 4)
        let shakeAction2 = SKAction.rotate(toAngle: -degree, duration: shakeAnimDuration / 4)
        ball.spriteNode.run(SKAction.repeat(SKAction.sequence([shakeAction1, shakeAction0, shakeAction2, shakeAction0]), count: 2)) {
            completion()
        }
    }
    
    private func openHalfOfBallResult(completion: @escaping (_ bodyBall: SKSpriteNode) -> Void) {
        guard let ballResult = ballResult else { return }
        let ballSpriteNode = ballResult.spriteNode
        
        let ballScaleSize = CGSize(width: size.width / (800 / 400), height: size.width / (800 / 395))
        let pieceSize = CGSize(width: ballScaleSize.width, height: size.width / (800 / 230))
        
        // add two piece node of ball
        let paddingCurve = size.width / (800 / 32)
        let yAnchor: CGFloat = paddingCurve / 230
        let ballCap = SKSpriteNode(imageNamed: "ball_cap")
        ballCap.size = pieceSize
        ballCap.anchorPoint = CGPoint(x: 0, y: yAnchor)
        ballCap.position = CGPoint(x: midX - ballScaleSize.width / 2, y: ballSpriteNode.position.y)
        ballCap.zPosition = 1
        addChild(ballCap)
        
        
        let bodyBall = SKSpriteNode(imageNamed: "body_\(ballResult.texture)")
        bodyBall.size = pieceSize
        bodyBall.position = CGPoint(x: midX, y: ballSpriteNode.position.y - ((ballScaleSize.height - pieceSize.height) / 2))
        bodyBall.zPosition = 0.5
        addChild(bodyBall)
        
        // hide ball sprite node result
        ballSpriteNode.alpha = 0
        
        // animate open ball cap
        let rotateAction = SKAction.rotate(byAngle: .pi / (180 / 135), duration: openBallAnimDuration)
        let fadeOutAction = SKAction.fadeOut(withDuration: openBallAnimDuration)
        ballCap.run(rotateAction)
        ballCap.run(fadeOutAction) {
            ballCap.removeFromParent()
            completion(bodyBall)
        }
    }
    
    private func showCoinAndMoveToCenter() {
        guard let ballSpriteResult = ballResult?.spriteNode else { return }
        let paddingCurve = size.width / (800 / 32)
        let coinNode = SKSpriteNode(imageNamed: "coin")
        coinNode.size = CGSize(width: size.width / (800 / 200), height: size.width / (800 / 210))
        let y = ballSpriteResult.position.y + coinNode.size.height / 2 - paddingCurve
        coinNode.position = CGPoint(x: midX, y: y)
        coinNode.zPosition = 1
        addChild(coinNode)
        
        showStarAround(coinNode)
        handleMoveCoinAnim(coinNode: coinNode) {
            ballSpriteResult.removeFromParent()
        }
    }
    
    private func handleMoveCoinAnim(coinNode: SKSpriteNode,_ completion: @escaping () -> Void) {
        let scaleSize = CGSize(width: coinNode.size.width * 1.8, height: coinNode.size.height * 1.8)
        let currentSize = coinNode.size
        let distanceSize = CGSize(width: scaleSize.width - currentSize.width, height: scaleSize.height - currentSize.height)
        
        let targetPoint = CGPoint(x: midX, y: -midY + coinNode.size.height / 2)
        let currentY = coinNode.position.y
        let moveDistance = targetPoint.y - currentY
        
        
        let action = SKAction.customAction(
            withDuration: moveCoinAnimDuration,
            actionBlock: { [weak self] (coinNode, elapsedTime) in
                guard let `self` = self, let coinNode = coinNode as? SKSpriteNode else { return }
                
                let percent = elapsedTime / CGFloat(self.moveCoinAnimDuration)
                coinNode.size = CGSize(width: currentSize.width + distanceSize.width * percent,
                                       height: currentSize.height + distanceSize.height * percent)
                
                coinNode.position = CGPoint(x: self.midX, y: currentY + (moveDistance * percent))
                
                // move star follow coin node
                self.starNodes.forEach { (star) in
                    self.updateStarNodePosition(at: star, follow: coinNode)
                }
        })
        
        coinNode.run(action) {
            completion()
        }
    }
    
    private func showStarAround(_ coinNode: SKSpriteNode) {
        let starSize = CGSize(width: size.width / (800 / 40), height: size.width / (800 / 65))
        
        for i in 0..<4 {
            let starNode = SKSpriteNode(imageNamed: "star")
            starNode.size = starSize
            starNode.name = "star_\(i)"
            starNode.zPosition = 1
            self.addChild(starNode)
            starNodes.append(starNode)
            updateStarNodePosition(at: starNode, follow: coinNode)
        }
        
        randomStarFadeInOut()
    }
    
    private func updateStarNodePosition(
        at starNode: SKSpriteNode,
        follow coinNode: SKSpriteNode,
        hSpacing: CGFloat = 8.0,
        vSpacing: CGFloat = 8.0
    ) {
        let hSpacing: CGFloat = 8.0
        guard let starId = starNode.name,
            let starIndex = Int(starId.components(separatedBy: "star_")[1]),
            let currentIndex = starNodes.firstIndex(of: starNode)
            else { return }
        
        switch starIndex {
        case 0:
            starNodes[currentIndex].position = CGPoint(x: coinNode.frame.minX - hSpacing, y: coinNode.frame.maxY + vSpacing)
        case 1:
            starNodes[currentIndex].position = CGPoint(x: coinNode.frame.maxX + hSpacing, y: coinNode.frame.maxY - vSpacing)
        case 2:
            starNodes[currentIndex].position = CGPoint(x: coinNode.frame.minX - hSpacing, y: coinNode.frame.minY - vSpacing)
        case 3:
            starNodes[currentIndex].position = CGPoint(x: coinNode.frame.maxX + hSpacing, y: coinNode.frame.minY + vSpacing)
        default:
            break
        }
    }
    
    private func randomStarFadeInOut() {
        starNodes.shuffle()
        for i in 0..<starNodes.count {
            let fadeInOutAction = SKAction.repeat(SKAction.sequence([SKAction.fadeOut(withDuration: 1), SKAction.fadeIn(withDuration: 1)]), count: Int.max)
            // delay 0.5 second
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + TimeInterval(Double(i) * 0.5)) { [unowned self] in
                self.starNodes[i].run(fadeInOutAction)
            }
        }
    }
    
    // MARK: - Actions
    @objc private func handleAnimationTime() {
        guard displayLink != nil else { return }
        let now = Date()
        let eslapsedTime = now.timeIntervalSince(decreaseStartTime)
        if eslapsedTime > TimeInterval(boxAnimDuration) {
            displayLink?.invalidate()
            displayLink = nil
            descreaseDetitutionTo(value: 0)
            openDoorToGetBall()
        } else {
            // caculate percent eslapsedTime with duration
            let percent = eslapsedTime / TimeInterval(boxAnimDuration)
            descreaseDetitutionTo(value: CGFloat(1 - percent))
        }
    }
    
}
