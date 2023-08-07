import Foundation
#if !COCOAPODS
import ApolloAPI
#endif

struct MultipartResponseDeferParser: MultipartResponseSpecificationParser {
  public enum ParsingError: Swift.Error, LocalizedError, Equatable {
    case unsupportedContentType(type: String)
    case cannotParseChunkData
    case cannotParsePayloadData

    public var errorDescription: String? {
      switch self {

      case let .unsupportedContentType(type):
        return "Unsupported content type: application/json is required but got \(type)."
      case .cannotParseChunkData:
        return "The chunk data could not be parsed."
      case .cannotParsePayloadData:
        return "The payload data could not be parsed."
      }
    }
  }

  private enum DataLine {
    case contentHeader(type: String)
    case json(object: JSONObject)
    case unknown

    init(_ value: String) {
      self = Self.parse(value)
    }

    private static func parse(_ dataLine: String) -> DataLine {
      var contentTypeHeader: StaticString { "content-type:" }

      if dataLine.starts(with: contentTypeHeader.description) {
        let contentType = (dataLine
          .components(separatedBy: ":").last ?? dataLine
        ).trimmingCharacters(in: .whitespaces)

        return .contentHeader(type: contentType)
      }

      if
        let data = dataLine.data(using: .utf8),
        let jsonObject = try? JSONSerializationFormat.deserialize(data: data) as? JSONObject
      {
        return .json(object: jsonObject)
      }

      return .unknown
    }
  }

  static let protocolSpec: String = "deferSpec=20220824"

  static func parse(
    chunk: String,
    dataHandler: ((Data) -> Void),
    errorHandler: ((Error) -> Void)
  ) {
    for dataLine in chunk.components(separatedBy: Self.dataLineSeparator.description) {
      switch DataLine(dataLine.trimmingCharacters(in: .newlines)) {
      case let .contentHeader(type):
        guard type == "application/json" else {
          errorHandler(ParsingError.unsupportedContentType(type: type))
          return
        }

      case let .json(object):
        if let label = object.label {
        }

        if let path = object.path {
        }

        if let hasNext = object.hasNext {
        }

        if let incremental = object.incremental {

        } else {
          guard
            let _ = object.data,
            let serialized: Data = try? JSONSerializationFormat.serialize(value: object)
          else {
            errorHandler(ParsingError.cannotParsePayloadData)
            return
          }

          dataHandler(serialized)
        }

      case .unknown:
        errorHandler(ParsingError.cannotParseChunkData)
      }
    }
  }
}

fileprivate extension JSONObject {
  var label: String? {
    self["label"] as? String
  }

  var path: [String]? {
    self["path"] as? [String]
  }

  var hasNext: Bool? {
    self["hasNext"] as? Bool
  }

  var data: JSONObject? {
    self["data"] as? JSONObject
  }

  var incremental: JSONObject? {
    self["incremental"] as? JSONObject
  }
}
