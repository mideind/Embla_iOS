#if !defined(GPB_GRPC_FORWARD_DECLARE_MESSAGE_PROTO) || !GPB_GRPC_FORWARD_DECLARE_MESSAGE_PROTO
#import "google/longrunning/Operations.pbobjc.h"
#endif

#if !defined(GPB_GRPC_PROTOCOL_ONLY) || !GPB_GRPC_PROTOCOL_ONLY
#import <ProtoRPC/ProtoService.h>
#import <ProtoRPC/ProtoRPC.h>
#import <RxLibrary/GRXWriteable.h>
#import <RxLibrary/GRXWriter.h>
#endif

@class CancelOperationRequest;
@class DeleteOperationRequest;
@class GPBEmpty;
@class GetOperationRequest;
@class ListOperationsRequest;
@class ListOperationsResponse;
@class Operation;
@class WaitOperationRequest;

#if !defined(GPB_GRPC_FORWARD_DECLARE_MESSAGE_PROTO) || !GPB_GRPC_FORWARD_DECLARE_MESSAGE_PROTO
  #import "google/api/Annotations.pbobjc.h"
  #import "google/api/Client.pbobjc.h"
#if defined(GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS) && GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS
  #import <Protobuf/Any.pbobjc.h>
#else
  #import "google/protobuf/Any.pbobjc.h"
#endif
#if defined(GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS) && GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS
  #import <Protobuf/Duration.pbobjc.h>
#else
  #import "google/protobuf/Duration.pbobjc.h"
#endif
#if defined(GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS) && GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS
  #import <Protobuf/Empty.pbobjc.h>
#else
  #import "google/protobuf/Empty.pbobjc.h"
#endif
  #import "google/rpc/Status.pbobjc.h"
  #import "google/protobuf/Descriptor.pbobjc.h"
#endif

@class GRPCProtoCall;


NS_ASSUME_NONNULL_BEGIN

@protocol Operations <NSObject>

#pragma mark ListOperations(ListOperationsRequest) returns (ListOperationsResponse)


- (void)listOperationsWithRequest:(ListOperationsRequest *)request handler:(void(^)(ListOperationsResponse *_Nullable response, NSError *_Nullable error))handler;


- (GRPCProtoCall *)RPCToListOperationsWithRequest:(ListOperationsRequest *)request handler:(void(^)(ListOperationsResponse *_Nullable response, NSError *_Nullable error))handler;


#pragma mark GetOperation(GetOperationRequest) returns (Operation)

/**
 * Gets the latest state of a long-running operation.  Clients can use this
 * method to poll the operation result at intervals as recommended by the API
 * service.
 */
- (void)getOperationWithRequest:(GetOperationRequest *)request handler:(void(^)(Operation *_Nullable response, NSError *_Nullable error))handler;

/**
 * Gets the latest state of a long-running operation.  Clients can use this
 * method to poll the operation result at intervals as recommended by the API
 * service.
 */
- (GRPCProtoCall *)RPCToGetOperationWithRequest:(GetOperationRequest *)request handler:(void(^)(Operation *_Nullable response, NSError *_Nullable error))handler;


#pragma mark DeleteOperation(DeleteOperationRequest) returns (Empty)

/**
 * Deletes a long-running operation. This method indicates that the client is
 * no longer interested in the operation result. It does not cancel the
 * operation. If the server doesn't support this method, it returns
 * `google.rpc.Code.UNIMPLEMENTED`.
 */
- (void)deleteOperationWithRequest:(DeleteOperationRequest *)request handler:(void(^)(GPBEmpty *_Nullable response, NSError *_Nullable error))handler;

/**
 * Deletes a long-running operation. This method indicates that the client is
 * no longer interested in the operation result. It does not cancel the
 * operation. If the server doesn't support this method, it returns
 * `google.rpc.Code.UNIMPLEMENTED`.
 */
- (GRPCProtoCall *)RPCToDeleteOperationWithRequest:(DeleteOperationRequest *)request handler:(void(^)(GPBEmpty *_Nullable response, NSError *_Nullable error))handler;


#pragma mark CancelOperation(CancelOperationRequest) returns (Empty)

/**
 * Starts asynchronous cancellation on a long-running operation.  The server
 * makes a best effort to cancel the operation, but success is not
 * guaranteed.  If the server doesn't support this method, it returns
 * `google.rpc.Code.UNIMPLEMENTED`.  Clients can use
 * [Operations.GetOperation][google.longrunning.Operations.GetOperation] or
 * other methods to check whether the cancellation succeeded or whether the
 * operation completed despite cancellation. On successful cancellation,
 * the operation is not deleted; instead, it becomes an operation with
 * an [Operation.error][google.longrunning.Operation.error] value with a [google.rpc.Status.code][google.rpc.Status.code] of 1,
 * corresponding to `Code.CANCELLED`.
 */
- (void)cancelOperationWithRequest:(CancelOperationRequest *)request handler:(void(^)(GPBEmpty *_Nullable response, NSError *_Nullable error))handler;

/**
 * Starts asynchronous cancellation on a long-running operation.  The server
 * makes a best effort to cancel the operation, but success is not
 * guaranteed.  If the server doesn't support this method, it returns
 * `google.rpc.Code.UNIMPLEMENTED`.  Clients can use
 * [Operations.GetOperation][google.longrunning.Operations.GetOperation] or
 * other methods to check whether the cancellation succeeded or whether the
 * operation completed despite cancellation. On successful cancellation,
 * the operation is not deleted; instead, it becomes an operation with
 * an [Operation.error][google.longrunning.Operation.error] value with a [google.rpc.Status.code][google.rpc.Status.code] of 1,
 * corresponding to `Code.CANCELLED`.
 */
- (GRPCProtoCall *)RPCToCancelOperationWithRequest:(CancelOperationRequest *)request handler:(void(^)(GPBEmpty *_Nullable response, NSError *_Nullable error))handler;


#pragma mark WaitOperation(WaitOperationRequest) returns (Operation)

/**
 * Waits until the specified long-running operation is done or reaches at most
 * a specified timeout, returning the latest state.  If the operation is
 * already done, the latest state is immediately returned.  If the timeout
 * specified is greater than the default HTTP/RPC timeout, the HTTP/RPC
 * timeout is used.  If the server does not support this method, it returns
 * `google.rpc.Code.UNIMPLEMENTED`.
 * Note that this method is on a best-effort basis.  It may return the latest
 * state before the specified timeout (including immediately), meaning even an
 * immediate response is no guarantee that the operation is done.
 */
- (void)waitOperationWithRequest:(WaitOperationRequest *)request handler:(void(^)(Operation *_Nullable response, NSError *_Nullable error))handler;

/**
 * Waits until the specified long-running operation is done or reaches at most
 * a specified timeout, returning the latest state.  If the operation is
 * already done, the latest state is immediately returned.  If the timeout
 * specified is greater than the default HTTP/RPC timeout, the HTTP/RPC
 * timeout is used.  If the server does not support this method, it returns
 * `google.rpc.Code.UNIMPLEMENTED`.
 * Note that this method is on a best-effort basis.  It may return the latest
 * state before the specified timeout (including immediately), meaning even an
 * immediate response is no guarantee that the operation is done.
 */
- (GRPCProtoCall *)RPCToWaitOperationWithRequest:(WaitOperationRequest *)request handler:(void(^)(Operation *_Nullable response, NSError *_Nullable error))handler;


@end


#if !defined(GPB_GRPC_PROTOCOL_ONLY) || !GPB_GRPC_PROTOCOL_ONLY
/**
 * Basic service implementation, over gRPC, that only does
 * marshalling and parsing.
 */
@interface Operations : GRPCProtoService<Operations>
- (instancetype)initWithHost:(NSString *)host NS_DESIGNATED_INITIALIZER;
+ (instancetype)serviceWithHost:(NSString *)host;
@end
#endif

NS_ASSUME_NONNULL_END

