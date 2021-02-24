#if !defined(GPB_GRPC_FORWARD_DECLARE_MESSAGE_PROTO) || !GPB_GRPC_FORWARD_DECLARE_MESSAGE_PROTO
#import "google/bytestream/Bytestream.pbobjc.h"
#endif

#if !defined(GPB_GRPC_PROTOCOL_ONLY) || !GPB_GRPC_PROTOCOL_ONLY
#import <ProtoRPC/ProtoService.h>
#import <ProtoRPC/ProtoRPC.h>
#import <RxLibrary/GRXWriteable.h>
#import <RxLibrary/GRXWriter.h>
#endif

@class QueryWriteStatusRequest;
@class QueryWriteStatusResponse;
@class ReadRequest;
@class ReadResponse;
@class WriteRequest;
@class WriteResponse;

#if !defined(GPB_GRPC_FORWARD_DECLARE_MESSAGE_PROTO) || !GPB_GRPC_FORWARD_DECLARE_MESSAGE_PROTO
  #import "google/api/Annotations.pbobjc.h"
#if defined(GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS) && GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS
  #import <Protobuf/Wrappers.pbobjc.h>
#else
  #import "google/protobuf/Wrappers.pbobjc.h"
#endif
#endif

@class GRPCProtoCall;


NS_ASSUME_NONNULL_BEGIN

@protocol ByteStream <NSObject>

#pragma mark Read(ReadRequest) returns (stream ReadResponse)

/**
 * `Read()` is used to retrieve the contents of a resource as a sequence
 * of bytes. The bytes are returned in a sequence of responses, and the
 * responses are delivered as the results of a server-side streaming RPC.
 */
- (void)readWithRequest:(ReadRequest *)request eventHandler:(void(^)(BOOL done, ReadResponse *_Nullable response, NSError *_Nullable error))eventHandler;

/**
 * `Read()` is used to retrieve the contents of a resource as a sequence
 * of bytes. The bytes are returned in a sequence of responses, and the
 * responses are delivered as the results of a server-side streaming RPC.
 */
- (GRPCProtoCall *)RPCToReadWithRequest:(ReadRequest *)request eventHandler:(void(^)(BOOL done, ReadResponse *_Nullable response, NSError *_Nullable error))eventHandler;


#pragma mark Write(stream WriteRequest) returns (WriteResponse)

/**
 * `Write()` is used to send the contents of a resource as a sequence of
 * bytes. The bytes are sent in a sequence of request protos of a client-side
 * streaming RPC.
 * 
 * A `Write()` action is resumable. If there is an error or the connection is
 * broken during the `Write()`, the client should check the status of the
 * `Write()` by calling `QueryWriteStatus()` and continue writing from the
 * returned `committed_size`. This may be less than the amount of data the
 * client previously sent.
 * 
 * Calling `Write()` on a resource name that was previously written and
 * finalized could cause an error, depending on whether the underlying service
 * allows over-writing of previously written resources.
 * 
 * When the client closes the request channel, the service will respond with
 * a `WriteResponse`. The service will not view the resource as `complete`
 * until the client has sent a `WriteRequest` with `finish_write` set to
 * `true`. Sending any requests on a stream after sending a request with
 * `finish_write` set to `true` will cause an error. The client **should**
 * check the `WriteResponse` it receives to determine how much data the
 * service was able to commit and whether the service views the resource as
 * `complete` or not.
 */
- (void)writeWithRequestsWriter:(GRXWriter *)requestWriter handler:(void(^)(WriteResponse *_Nullable response, NSError *_Nullable error))handler;

/**
 * `Write()` is used to send the contents of a resource as a sequence of
 * bytes. The bytes are sent in a sequence of request protos of a client-side
 * streaming RPC.
 * 
 * A `Write()` action is resumable. If there is an error or the connection is
 * broken during the `Write()`, the client should check the status of the
 * `Write()` by calling `QueryWriteStatus()` and continue writing from the
 * returned `committed_size`. This may be less than the amount of data the
 * client previously sent.
 * 
 * Calling `Write()` on a resource name that was previously written and
 * finalized could cause an error, depending on whether the underlying service
 * allows over-writing of previously written resources.
 * 
 * When the client closes the request channel, the service will respond with
 * a `WriteResponse`. The service will not view the resource as `complete`
 * until the client has sent a `WriteRequest` with `finish_write` set to
 * `true`. Sending any requests on a stream after sending a request with
 * `finish_write` set to `true` will cause an error. The client **should**
 * check the `WriteResponse` it receives to determine how much data the
 * service was able to commit and whether the service views the resource as
 * `complete` or not.
 */
- (GRPCProtoCall *)RPCToWriteWithRequestsWriter:(GRXWriter *)requestWriter handler:(void(^)(WriteResponse *_Nullable response, NSError *_Nullable error))handler;


#pragma mark QueryWriteStatus(QueryWriteStatusRequest) returns (QueryWriteStatusResponse)

/**
 * `QueryWriteStatus()` is used to find the `committed_size` for a resource
 * that is being written, which can then be used as the `write_offset` for
 * the next `Write()` call.
 * 
 * If the resource does not exist (i.e., the resource has been deleted, or the
 * first `Write()` has not yet reached the service), this method returns the
 * error `NOT_FOUND`.
 * 
 * The client **may** call `QueryWriteStatus()` at any time to determine how
 * much data has been processed for this resource. This is useful if the
 * client is buffering data and needs to know which data can be safely
 * evicted. For any sequence of `QueryWriteStatus()` calls for a given
 * resource name, the sequence of returned `committed_size` values will be
 * non-decreasing.
 */
- (void)queryWriteStatusWithRequest:(QueryWriteStatusRequest *)request handler:(void(^)(QueryWriteStatusResponse *_Nullable response, NSError *_Nullable error))handler;

/**
 * `QueryWriteStatus()` is used to find the `committed_size` for a resource
 * that is being written, which can then be used as the `write_offset` for
 * the next `Write()` call.
 * 
 * If the resource does not exist (i.e., the resource has been deleted, or the
 * first `Write()` has not yet reached the service), this method returns the
 * error `NOT_FOUND`.
 * 
 * The client **may** call `QueryWriteStatus()` at any time to determine how
 * much data has been processed for this resource. This is useful if the
 * client is buffering data and needs to know which data can be safely
 * evicted. For any sequence of `QueryWriteStatus()` calls for a given
 * resource name, the sequence of returned `committed_size` values will be
 * non-decreasing.
 */
- (GRPCProtoCall *)RPCToQueryWriteStatusWithRequest:(QueryWriteStatusRequest *)request handler:(void(^)(QueryWriteStatusResponse *_Nullable response, NSError *_Nullable error))handler;


@end


#if !defined(GPB_GRPC_PROTOCOL_ONLY) || !GPB_GRPC_PROTOCOL_ONLY
/**
 * Basic service implementation, over gRPC, that only does
 * marshalling and parsing.
 */
@interface ByteStream : GRPCProtoService<ByteStream>
- (instancetype)initWithHost:(NSString *)host NS_DESIGNATED_INITIALIZER;
+ (instancetype)serviceWithHost:(NSString *)host;
@end
#endif

NS_ASSUME_NONNULL_END

