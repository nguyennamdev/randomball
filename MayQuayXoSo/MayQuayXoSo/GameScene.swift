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

class GameScene: SKScene {
    
    // MARK: - Public properties
    var boxAnimDuration: TimeInterval = 2.0
    var ballWidth: CGFloat = 120
    var shakeAnimDuration: TimeInterval = 1
    var moveBallAnimDuration: TimeInterval = 1
    
    // MARK: - Private properties
    private var balls: [SKSpriteNode] = []
    private var displayLink: CADisplayLink?
    private var decreaseStartTime: Date!
    private var midX: CGFloat = 0.0
    private var midY: CGFloat = 0.0
    private var boxEdge: [SKSpriteNode] = []
    private var sizeConfig: SizeConfig!
    private var isOpenningBox: Bool = false
    private var lockNode: SKSpriteNode!
    private var ballResultOldPosition: CGPoint?
    private var ballResult: SKSpriteNode?
    private var ballResultIsIdle: Bool = false
    private var timeGotResult: TimeInterval = 0
    
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
        if closeDoorToGetOneBall(at: currentTime) && !ballResultIsIdle {
            guard currentTime != self.timeGotResult else { return }
            if self.waitBallOutOfBoxAndIdle(ball: self.ballResult) {
                self.animationBallResultAnimate()
            }
        }
    }
    
    // MARK: - Public function
    public func impulseBalls() {
        self.initDisplayLink()
        self.balls.forEach { (node) in
            node.physicsBody?.applyImpulse(CGVector(dx: size.height,
                                                    dy: size.height))
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
            let ball = SKSpriteNode(imageNamed: "ball_\(ballRan)")
            ball.name = "ball_\(balls.count)"
            ball.size = CGSize(width: ballWidth, height: ballWidth)
            ball.position = CGPoint(x: CGFloat.random(in: ballWidth..<size.width - ballWidth),
                                    y: -(sizeConfig.boxHeight - sizeConfig.edgeWeight) + ballWidth)
            
            ball.physicsBody = SKPhysicsBody(circleOfRadius: ball.size.width / 2)
            ball.physicsBody?.restitution = 1
            //        ball.physicsBody?.friction = 0
            //        ball.physicsBody?.categoryBitMask = 2
            //        ball.physicsBody?.collisionBitMask = 1
            //        ball.physicsBody?.fieldBitMask = 0
            //        ball.physicsBody?.contactTestBitMask = 1
            ball.zPosition = 0.5
            addChild(ball)
            balls.append(ball)
        }
    }
    
    private func initDisplayLink() {
        decreaseStartTime = Date()
        displayLink = CADisplayLink(target: self, selector: #selector(handleAnimationTime))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    private func descreaseDetitutionTo(value: CGFloat) {
        self.balls.forEach { (node) in
            node.physicsBody?.restitution = value
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
        let spaceEdge = SKSpriteNode(color: #colorLiteral(red: 0.1336817443, green: 0.09179023653, blue: 0.07689016312, alpha: 1), size: CGSize(width: sizeConfig.holeWidth, height: sizeConfig.edgeWeight))
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
            let ballFilter = balls.filter({ (ball) -> Bool in
                let topY = -ball.position.y - ball.size.height / 2
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
                ballResultOldPosition = ballResult?.position
                timeGotResult = time
                return true
            }
        }
        return false
    }
    
    private func waitBallOutOfBoxAndIdle(ball: SKSpriteNode?) -> Bool {
        guard let ballResultOldPosition = self.ballResultOldPosition,
            ballResultOldPosition == ball?.position else {
                self.ballResultOldPosition = ball?.position
                return false
        }
        ballResultIsIdle = true
        return true
    }
    
    // MARK: - Animation functions
    private func rotateLockNodeAnimate() {
        let action = SKAction.rotate(toAngle: .pi / 2, duration: 1)
        lockNode.run(action)
    }
    
    private func animationBallResultAnimate() {
        guard let ballResult = self.ballResult else { return }
        ballResult.zPosition = 1
        ballResult.physicsBody = nil
        let ballScaleSize = CGSize(width: size.width / (800 / 400), height: size.width / (800 / 400))
        
        let moveAction = SKAction.moveBy(x: 0, y: midY - ballScaleSize.height / 2, duration: moveBallAnimDuration)
        let scaleAction = SKAction.scale(to: ballScaleSize, duration: moveBallAnimDuration)
        let fadeOutAction = SKAction.fadeOut(withDuration: moveBallAnimDuration)
        let rotateAction = SKAction.rotate(toAngle: 0, duration: moveBallAnimDuration)
        
       
        self.children.forEach({ node in
            if node != ballResult {
                node.run(fadeOutAction)
            }
        })
        ballResult.run(rotateAction)
        ballResult.run(scaleAction)
        ballResult.run(moveAction) { [weak ballResult, weak self] in
            guard let `self` = self, let ballResult = ballResult else { return }
            self.shakeAnimation(ball: ballResult)
        }
        
    }
    
    private func shakeAnimation(ball: SKSpriteNode) {
        let shakeAction1 = SKAction.rotate(toAngle: .pi / 18, duration: shakeAnimDuration / 4)
        let shakeAction0 = SKAction.rotate(toAngle: 0, duration: shakeAnimDuration / 4)
        let shakeAction2 = SKAction.rotate(toAngle: -.pi / 18, duration: shakeAnimDuration / 4)
        ball.run(SKAction.repeat(SKAction.sequence([shakeAction1, shakeAction0, shakeAction2, shakeAction0]), count: 2))
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
