enum MLTAudioEffect {
  case reverb
  case distortion
  case delay
}

extension MLTAudioEffect {

  var title: String {
    switch self {
      case .reverb:
        return "audio_effect_reverb".localized
      case .distortion:
        return "audio_effect_distortion".localized
      case .delay:
        return "audio_effect_delay".localized
    }
  }
}
