import AVFoundation
import UIKit.UIImage

protocol VideoPreviewGenerator {
  func thumbnail(for video: URL) -> UIImage?
}

class DefailtVideoPreviewGenerator: VideoPreviewGenerator {

  func thumbnail(for video: URL) -> UIImage? {
    let asset = AVAsset(url: video)
    let imageGenerator = AVAssetImageGenerator(asset: asset)
    let time = CMTimeMake(value: 1, timescale: 1)
    guard let imageRef = try? imageGenerator.copyCGImage(at: time, actualTime: nil) else { return nil }
    return UIImage(cgImage: imageRef)
  }
}
