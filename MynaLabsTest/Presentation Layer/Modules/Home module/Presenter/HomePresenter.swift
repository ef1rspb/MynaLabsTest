import Foundation
import AVFoundation

protocol HomeView: class {
  func shareAudio(url: URL)
}

protocol HomePresenter {

  func selectVideoButtonPressed()
  func loadVideo(by url: URL)
}

final class HomePresenterImpl: HomePresenter {

  private weak var view: HomeView?

  init(view: HomeView) {
    self.view = view
  }

  func selectVideoButtonPressed() {
    print("asdasd")
  }

  func loadVideo(by url: URL) {
    exportAudioFromVideo(url: url)
  }

  private func exportAudioFromVideo(url: URL) {
    let videoAsset = AVAsset(url: url)
    guard let temp = createTempDirectory() else { return }
    videoAsset.writeAudioTrack(to: temp, success: { [weak self] in
      print("asdasd")
      self?.appleEffect(to: temp)
    }) { error in
      print(error)
    }
  }

  private func appleEffect(to url: URL) {
    let sourceFile: AVAudioFile
    let format: AVAudioFormat
    do {
      sourceFile = try AVAudioFile(forReading: url)
      format = sourceFile.processingFormat
    } catch {
      fatalError("Unable to load the source audio file: \(error.localizedDescription).")
    }

    let engine = AVAudioEngine()
    do {
      try engine.enableManualRenderingMode(
        .offline,
        format: sourceFile.processingFormat,
        maximumFrameCount: 1024
      )
    } catch {
      print(error.localizedDescription)
    }

    let player = AVAudioPlayerNode()
    let reverb = AVAudioUnitReverb()

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
      fatalError("Unable to start audio engine: \(error).")
    }

    let outputFile: AVAudioFile
    do {
      let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      let outputURL = documentsURL.appendingPathComponent("output.caf")
      outputFile = try AVAudioFile(forWriting: outputURL, settings: sourceFile.fileFormat.settings)
    } catch {
      fatalError("Unable to open output audio file: \(error).")
    }

    // The output buffer to which the engine renders the processed data.
    guard let buffer = AVAudioPCMBuffer(
      pcmFormat: engine.manualRenderingFormat,
      frameCapacity: engine.manualRenderingMaximumFrameCount
      ) else {
        print("buffer(")
        return
    }

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
            fatalError("The manual rendering failed.")
        }
      } catch {
        fatalError("The manual rendering failed: \(error).")
      }
    }

    // Stop the player node and engine.
    player.stop()
    engine.stop()

    DispatchQueue.main.async { [weak view] in
      view?.shareAudio(url: outputFile.url)
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
