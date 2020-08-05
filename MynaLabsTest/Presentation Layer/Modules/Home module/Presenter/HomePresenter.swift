import Foundation
import AVFoundation

protocol HomeView: class {
  func shareAudio(url: URL)
}

protocol HomePresenter {

  func selectVideoButtonPressed()
  func loadVideo(by url: URL)
}

private typealias ProcessingCompletion = (_ error: Error?, _ url: URL?) -> Void

final class HomePresenterImpl: HomePresenter {

  private weak var view: HomeView?

  init(view: HomeView) {
    self.view = view
  }

  func selectVideoButtonPressed() {
    print("asdasd")
  }

  func loadVideo(by url: URL) {
    exportAudioFromVideo(videoUrl: url)
  }

  private func exportAudioFromVideo(videoUrl: URL) {
    let videoAsset = AVAsset(url: videoUrl)
    guard let temp = createTempDirectory() else { return }
    videoAsset.writeAudioTrack(to: temp, success: { [weak self] in
      print("asdasd")
      self?.appleEffectToAudio(to: temp) { error, url in
        guard error == nil else { return }
        guard let audioUrl = url else { return }
        self?.mergeVideoAndAudio(videoUrl: videoUrl, audioUrl: audioUrl) { error, url in
          guard error == nil else { return }
          guard let videoUrl = url else { return }
          self?.view?.shareAudio(url: videoUrl)
        }
      }
    }) { error in
      print(error)
    }
  }

  private func appleEffectToAudio(to url: URL, completion: @escaping ProcessingCompletion) {
    let sourceFile: AVAudioFile
    let format: AVAudioFormat
    do {
      sourceFile = try AVAudioFile(forReading: url)
      format = sourceFile.processingFormat
    } catch {
      print("Unable to load the source audio file: \(error.localizedDescription).")
      completion(error, nil)
      return
    }

    let engine = AVAudioEngine()
    do {
      try engine.enableManualRenderingMode(
        .offline,
        format: sourceFile.processingFormat,
        maximumFrameCount: 1024
      )
    } catch {
      completion(error, nil)
    }

    let player = AVAudioPlayerNode()
    let reverb = AVAudioUnitReverb()

    func stopOnError() {
      player.stop()
      engine.stop()
    }

    engine.attach(player)
    engine.attach(reverb)

    // Set the desired reverb parameters.
    reverb.loadFactoryPreset(.mediumHall)
    reverb.wetDryMix = 50

    // Connect the nodes.
    engine.connect(player, to: reverb, format: format)
    engine.connect(reverb, to: engine.mainMixerNode, format: format)

    // Schedule the source file.
    player.scheduleFile(sourceFile, at: nil)

    do {
      try engine.start()
      player.play()
    } catch {
      stopOnError()
      completion(error, nil)
    }

    let outputFile: AVAudioFile
    do {
      let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      let outputURL = documentsURL.appendingPathComponent("output.caf")
      outputFile = try AVAudioFile(forWriting: outputURL, settings: sourceFile.fileFormat.settings)
    } catch {
      stopOnError()
      completion(error, nil)
      return
    }

    // The output buffer to which the engine renders the processed data.
    let buffer = AVAudioPCMBuffer(
      pcmFormat: engine.manualRenderingFormat,
      frameCapacity: engine.manualRenderingMaximumFrameCount
    )!

    while engine.manualRenderingSampleTime < sourceFile.length {
      do {
        let frameCount = sourceFile.length - engine.manualRenderingSampleTime
        let framesToRender = min(AVAudioFrameCount(frameCount), buffer.frameCapacity)

        let status = try engine.renderOffline(framesToRender, to: buffer)

        switch status {

          case .success:
            // The data rendered successfully. Write it to the output file.
            try outputFile.write(from: buffer)

          case .insufficientDataFromInputNode:
            // Applicable only when using the input node as one of the sources.
            break

          case .cannotDoInCurrentContext:
            // The engine couldn't render in the current render call.
            // Retry in the next iteration.
            break

          case .error:
            // An error occurred while rendering the audio.
            print("The manual rendering failed.")
          stopOnError()
        }
      } catch {
        print("The manual rendering failed: \(error).")
        stopOnError()
        completion(error, nil)
      }
    }

    // Stop the player node and engine.
    stopOnError()

    completion(nil, outputFile.url)
  }

  func mergeVideoAndAudio(
    videoUrl: URL,
    audioUrl: URL,
    shouldFlipHorizontally: Bool = false,
    completion: @escaping (_ error: Error?, _ url: URL?) -> Void
  ) {

    let mixComposition = AVMutableComposition()
    var mutableCompositionVideoTrack = [AVMutableCompositionTrack]()
    var mutableCompositionAudioTrack = [AVMutableCompositionTrack]()
    //var mutableCompositionAudioOfVideoTrack = [AVMutableCompositionTrack]()

    //start merge

    let aVideoAsset = AVAsset(url: videoUrl)
    let aAudioAsset = AVAsset(url: audioUrl)

    let compositionAddVideo = mixComposition.addMutableTrack(
      withMediaType: AVMediaType.video,
      preferredTrackID: kCMPersistentTrackID_Invalid
    )!

    let compositionAddAudio = mixComposition.addMutableTrack(
      withMediaType: AVMediaType.audio,
      preferredTrackID: kCMPersistentTrackID_Invalid
    )!

//    let compositionAddAudioOfVideo = mixComposition.addMutableTrack(
//      withMediaType: AVMediaType.audio,
//      preferredTrackID: kCMPersistentTrackID_Invalid
//    )!

    let aVideoAssetTrack: AVAssetTrack = aVideoAsset.tracks(withMediaType: AVMediaType.video)[0]
    //let aAudioOfVideoAssetTrack: AVAssetTrack? = aVideoAsset.tracks(withMediaType: AVMediaType.audio).first
    let aAudioAssetTrack: AVAssetTrack = aAudioAsset.tracks(withMediaType: AVMediaType.audio)[0]

    // Default must have tranformation
    //compositionAddVideo.preferredTransform = aVideoAssetTrack.preferredTransform

//    if shouldFlipHorizontally {
//      // Flip video horizontally
//      var frontalTransform: CGAffineTransform = CGAffineTransform(scaleX: -1.0, y: 1.0)
//      frontalTransform = frontalTransform.translatedBy(x: -aVideoAssetTrack.naturalSize.width, y: 0.0)
//      frontalTransform = frontalTransform.translatedBy(x: 0.0, y: -aVideoAssetTrack.naturalSize.width)
//      compositionAddVideo.preferredTransform = frontalTransform
//    }

    mutableCompositionVideoTrack.append(compositionAddVideo)
    mutableCompositionAudioTrack.append(compositionAddAudio)
    //mutableCompositionAudioOfVideoTrack.append(compositionAddAudioOfVideo)

    do {
      try mutableCompositionVideoTrack[0].insertTimeRange(
        CMTimeRangeMake(start: CMTime.zero, duration: aVideoAssetTrack.timeRange.duration),
        of: aVideoAssetTrack,
        at: CMTime.zero
      )

      //In my case my audio file is longer then video file so i took videoAsset duration
      //instead of audioAsset duration
      try mutableCompositionAudioTrack[0].insertTimeRange(
        CMTimeRangeMake(start: CMTime.zero, duration: aVideoAssetTrack.timeRange.duration),
        of: aAudioAssetTrack,
        at: CMTime.zero
      )

      // adding audio (of the video if exists) asset to the final composition
//      if let aAudioOfVideoAssetTrack = aAudioOfVideoAssetTrack {
//        try mutableCompositionAudioOfVideoTrack[0].insertTimeRange(
//          CMTimeRangeMake(start: CMTime.zero, duration: aVideoAssetTrack.timeRange.duration),
//          of: aAudioOfVideoAssetTrack,
//          at: CMTime.zero
//        )
//      }
    } catch {
      print(error.localizedDescription)
      completion(error, nil)
    }

    // Exporting
    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let savePathUrl = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("output.mov")!//documentsURL.appendingPathComponent("output.mov")

    do { // delete old video
      try FileManager.default.removeItem(at: savePathUrl)
    } catch {
      print(error.localizedDescription)
      //completion(error, nil)
    }

    let assetExport: AVAssetExportSession = AVAssetExportSession(
      asset: mixComposition,
      presetName: AVAssetExportPresetHighestQuality
    )!
    assetExport.outputFileType = .mov
    assetExport.outputURL = savePathUrl
    assetExport.shouldOptimizeForNetworkUse = true

    assetExport.exportAsynchronously { () -> Void in
      switch assetExport.status {
        case .completed:
          print("success")
          completion(nil, savePathUrl)
        case .failed:
          print("failed here \(assetExport.error?.localizedDescription ?? "error nil")")
          completion(assetExport.error, nil)
        case .cancelled:
          print("cancelled \(assetExport.error?.localizedDescription ?? "error nil")")
          completion(assetExport.error, nil)
        default:
          print("complete")
          completion(assetExport.error, nil)
      }
    }

  }
}

func createTempDirectory() -> URL? {

  guard let tempDirURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("myTempFile.caf") else {
    return nil
  }

  do { // delete old video
    try FileManager.default.removeItem(at: tempDirURL)
  } catch {
    print(error.localizedDescription)
  }

  do {
    try FileManager.default.createDirectory(at: tempDirURL, withIntermediateDirectories: true, attributes: nil)
  } catch {
    return nil
  }

  return tempDirURL
}
