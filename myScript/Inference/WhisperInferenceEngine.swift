import Foundation
import ExecuTorch

actor WhisperInferenceEngine {
    private var whisperModule: Module?
    private var preprocessorModule: Module?
    private var tokenizer: WhisperTokenizer?
    private var isLoaded = false

    func loadModel() throws {
        let bundle = Bundle.main
        let resourcePath = bundle.resourcePath ?? bundle.bundlePath

        let modelPath = (resourcePath as NSString).appendingPathComponent("Models/model.pte")
        let preprocessorPath = (resourcePath as NSString).appendingPathComponent("Models/whisper_preprocessor.pte")
        let tokenizerPath = (resourcePath as NSString).appendingPathComponent("Models/tokenizer.json")

        let fm = FileManager.default
        guard fm.fileExists(atPath: modelPath) else {
            throw InferenceError.modelNotFound("model.pte not found at \(modelPath)")
        }
        guard fm.fileExists(atPath: tokenizerPath) else {
            throw InferenceError.modelNotFound("tokenizer.json not found at \(tokenizerPath)")
        }

        tokenizer = try WhisperTokenizer(jsonURL: URL(fileURLWithPath: tokenizerPath))

        let whisper = Module(filePath: modelPath)
        try whisper.load()
        whisperModule = whisper

        if fm.fileExists(atPath: preprocessorPath) {
            let preprocessor = Module(filePath: preprocessorPath)
            try preprocessor.load()
            preprocessorModule = preprocessor
        }

        isLoaded = true
    }

    func transcribe(audioSamples: [Float]) throws -> String {
        guard isLoaded, let tokenizer else {
            throw InferenceError.modelNotLoaded
        }

        // Step 1: Preprocess audio → mel spectrogram
        var samples = audioSamples
        let melTensor: Tensor<Float>
        if let preprocessor = preprocessorModule {
            let inputTensor = Tensor<Float>(&samples, shape: [1, samples.count])
            let results = try preprocessor.forward(inputTensor)
            guard let firstResult = results.first,
                  let outputTensor: Tensor<Float> = firstResult.tensor() else {
                throw InferenceError.inferenceFailure("Preprocessor returned no output")
            }
            melTensor = outputTensor
        } else {
            // Pass raw audio directly if no preprocessor available
            melTensor = Tensor<Float>(&samples, shape: [1, samples.count])
        }

        // Step 2: Run whisper model → token IDs
        guard let whisper = whisperModule else {
            throw InferenceError.modelNotLoaded
        }
        let results = try whisper.forward(melTensor)

        // Step 3: Extract token IDs from output tensor and decode
        guard let firstResult = results.first,
              let outputTensor: Tensor<Int> = firstResult.tensor() else {
            // Try Float output and convert to Int
            if let firstResult = results.first,
               let floatTensor: Tensor<Float> = firstResult.tensor() {
                let tokenIds = floatTensor.scalars().map { Int($0) }
                return tokenizer.decode(tokenIds: tokenIds)
            }
            throw InferenceError.inferenceFailure("Model returned no output")
        }

        let tokenIds = outputTensor.scalars().map { Int($0) }
        let text = tokenizer.decode(tokenIds: tokenIds)

        return text
    }
}

nonisolated enum InferenceError: LocalizedError {
    case modelNotFound(String)
    case modelNotLoaded
    case inferenceFailure(String)

    var errorDescription: String? {
        switch self {
        case .modelNotFound(let msg): msg
        case .modelNotLoaded: "Model is not loaded"
        case .inferenceFailure(let msg): "Inference failed: \(msg)"
        }
    }
}
