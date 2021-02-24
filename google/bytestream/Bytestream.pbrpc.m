#if !defined(GPB_GRPC_PROTOCOL_ONLY) || !GPB_GRPC_PROTOCOL_ONLY
#import "google/bytestream/Bytestream.pbrpc.h"
#import "google/bytestream/Bytestream.pbobjc.h"
#import <ProtoRPC/ProtoRPC.h>
#import <RxLibrary/GRXWriter+Immediate.h>

#import "google/api/Annotations.pbobjc.h"
#if defined(GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS) && GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS
#import <Protobuf/Wrappers.pbobjc.h>
#else
#import "google/protobuf/Wrappers.pbobjc.h"
#endif

@implementation ByteStream

// Designated initializer
- (instancetype)initWithHost:(NSString *)host {
  self = [super initWithHost:host
                 packageName:@"google.bytestream"
                 serviceName:@"ByteStream"];
  return self;
}

// Override superclass initializer to disallow different package and service names.
- (instancetype)initWithHost:(NSString *)host
                 packageName:(NSString *)packageName
                 serviceName:(NSString *)serviceName {
  return [self initWithHost:host];
}

#pragma mark - Class Methods

+ (instancetype)serviceWithHost:(NSString *)host {
  return [[self alloc] initWithHost:host];
}

#pragma mark - Method Implementations

#pragma mark Read(ReadRequest) returns (stream ReadResponse)

/**
 * `Read()` is used to retrieve the contents of a resource as a sequence
 * of bytes. The bytes are returned in a sequence of responses, and the
 * responses are delivered as the results of a server-side streaming RPC.
 */
- (void)readWithRequest:(ReadRequest *)request eventHandler:(void(^)(BOOL done, ReadResponse *_Nullable response, NSError *_Nullable error))eventHandler{
  [[self RPCToReadWithRequest:request eventHandler:eventHandler] start];
}
// Returns a not-yet-started RPC object.
/**
 * `Read()` is used to retrieve the contents of a resource as a sequence
 * of bytes. The bytes are returned in a sequence of responses, and the
 * responses are delivered as the results of a server-side streaming RPC.
 */
- (GRPCProtoCall *)RPCToReadWithRequest:(ReadRequest *)request eventHandler:(void(^)(BOOL done, ReadResponse *_Nullable response, NSError *_Nullable error))eventHandler{
  return [self RPCToMethod:@"Read"
            requestsWriter:[GRXWriter writerWithValue:request]
             responseClass:[ReadResponse class]
        responsesWriteable:[GRXWriteable writeableWithEventHandler:eventHandler]];
}
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
- (void)writeWithRequestsWriter:(GRXWriter *)requestWriter handler:(void(^)(WriteResponse *_Nullable response, NSError *_Nullable error))handler{
  [[self RPCToWriteWithRequestsWriter:requestWriter handler:handler] start];
}
// Returns a not-yet-started RPC object.
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
- (GRPCProtoCall *)RPCToWriteWithRequestsWriter:(GRXWriter *)requestWriter handler:(void(^)(WriteResponse *_Nullable response, NSError *_Nullable error))handler{
  return [self RPCToMethod:@"Write"
            requestsWriter:requestWriter
             responseClass:[WriteResponse class]
        responsesWriteable:[GRXWriteable writeableWithSingleHandler:handler]];
}
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
- (void)queryWriteStatusWithRequest:(QueryWriteStatusRequest *)request handler:(void(^)(QueryWriteStatusResponse *_Nullable response, NSError *_Nullable error))handler{
  [[self RPCToQueryWriteStatusWithRequest:request handler:handler] start];
}
// Returns a not-yet-started RPC object.
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
- (GRPCProtoCall *)RPCToQueryWriteStatusWithRequest:(QueryWriteStatusRequest *)request handler:(void(^)(QueryWriteStatusResponse *_Nullable response, NSError *_Nullable error))handler{
  return [self RPCToMethod:@"QueryWriteStatus"
            requestsWriter:[GRXWriter writerWithValue:request]
             responseClass:[QueryWriteStatusResponse class]
        responsesWriteable:[GRXWriteable writeableWithSingleHandler:handler]];
}
@end
#endif
