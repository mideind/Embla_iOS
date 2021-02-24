#if !defined(GPB_GRPC_FORWARD_DECLARE_MESSAGE_PROTO) || !GPB_GRPC_FORWARD_DECLARE_MESSAGE_PROTO
#import "lr/transcript/v1alpha1/Transcript.pbobjc.h"
#endif

#if !defined(GPB_GRPC_PROTOCOL_ONLY) || !GPB_GRPC_PROTOCOL_ONLY
#import <ProtoRPC/ProtoService.h>
#import <ProtoRPC/ProtoRPC.h>
#import <RxLibrary/GRXWriteable.h>
#import <RxLibrary/GRXWriter.h>
#endif

@class AlignmentJob;
@class CancelAlignmentJobRequest;
@class CreateTranscriptRequest;
@class CreateTranscriptResponse;
@class DeleteTranscriptRequest;
@class ExportTranscriptRequest;
@class ExportTranscriptResponse;
@class GPBEmpty;
@class GetAlignmentJobRequest;
@class GetTranscriptJobRequest;
@class GetTranscriptRequest;
@class ListAlignmentJobsRequest;
@class ListAlignmentJobsResponse;
@class ListTranscriptJobsRequest;
@class ListTranscriptJobsResponse;
@class ListTranscriptsRequest;
@class ListTranscriptsResponse;
@class SubmitAlignmentJobRequest;
@class SubmitTranscriptJobRequest;
@class Transcript;
@class TranscriptJob;
@class UpdateTranscriptRequest;
@class WatchAlignmentJobsRequest;
@class WatchAlignmentJobsResponse;
@class WatchTranscriptJobsRequest;
@class WatchTranscriptJobsResponse;
@class WatchTranscriptsRequest;
@class WatchTranscriptsResponse;

#if !defined(GPB_GRPC_FORWARD_DECLARE_MESSAGE_PROTO) || !GPB_GRPC_FORWARD_DECLARE_MESSAGE_PROTO
  #import "google/api/Annotations.pbobjc.h"
  #import "google/api/Httpbody.pbobjc.h"
  #import "google/api/Client.pbobjc.h"
  #import "google/rpc/Status.pbobjc.h"
#if defined(GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS) && GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS
  #import <Protobuf/Timestamp.pbobjc.h>
#else
  #import "google/protobuf/Timestamp.pbobjc.h"
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
#endif

@class GRPCProtoCall;


NS_ASSUME_NONNULL_BEGIN

@protocol TranscriptService <NSObject>

#pragma mark SubmitTranscriptJob(SubmitTranscriptJobRequest) returns (TranscriptJob)

/**
 * Submit audio or video to be transcribed
 */
- (void)submitTranscriptJobWithRequest:(SubmitTranscriptJobRequest *)request handler:(void(^)(TranscriptJob *_Nullable response, NSError *_Nullable error))handler;

/**
 * Submit audio or video to be transcribed
 */
- (GRPCProtoCall *)RPCToSubmitTranscriptJobWithRequest:(SubmitTranscriptJobRequest *)request handler:(void(^)(TranscriptJob *_Nullable response, NSError *_Nullable error))handler;


#pragma mark GetTranscriptJob(GetTranscriptJobRequest) returns (TranscriptJob)

/**
 * Get status of submitted transcript job
 */
- (void)getTranscriptJobWithRequest:(GetTranscriptJobRequest *)request handler:(void(^)(TranscriptJob *_Nullable response, NSError *_Nullable error))handler;

/**
 * Get status of submitted transcript job
 */
- (GRPCProtoCall *)RPCToGetTranscriptJobWithRequest:(GetTranscriptJobRequest *)request handler:(void(^)(TranscriptJob *_Nullable response, NSError *_Nullable error))handler;


#pragma mark WatchTranscriptJobs(WatchTranscriptJobsRequest) returns (stream WatchTranscriptJobsResponse)

/**
 * Start watching for changes in submitted transcription jobs.
 * 
 * The first successful response will contain all `jobs` that match
 * `WatchTranscriptJobsRequest.filter`. Subsequent responses will have
 * `update=true` and `jobs` will contain only updated jobs.
 */
- (void)watchTranscriptJobsWithRequest:(WatchTranscriptJobsRequest *)request eventHandler:(void(^)(BOOL done, WatchTranscriptJobsResponse *_Nullable response, NSError *_Nullable error))eventHandler;

/**
 * Start watching for changes in submitted transcription jobs.
 * 
 * The first successful response will contain all `jobs` that match
 * `WatchTranscriptJobsRequest.filter`. Subsequent responses will have
 * `update=true` and `jobs` will contain only updated jobs.
 */
- (GRPCProtoCall *)RPCToWatchTranscriptJobsWithRequest:(WatchTranscriptJobsRequest *)request eventHandler:(void(^)(BOOL done, WatchTranscriptJobsResponse *_Nullable response, NSError *_Nullable error))eventHandler;


#pragma mark ListTranscriptJobs(ListTranscriptJobsRequest) returns (ListTranscriptJobsResponse)

- (void)listTranscriptJobsWithRequest:(ListTranscriptJobsRequest *)request handler:(void(^)(ListTranscriptJobsResponse *_Nullable response, NSError *_Nullable error))handler;

- (GRPCProtoCall *)RPCToListTranscriptJobsWithRequest:(ListTranscriptJobsRequest *)request handler:(void(^)(ListTranscriptJobsResponse *_Nullable response, NSError *_Nullable error))handler;


#pragma mark CreateTranscript(CreateTranscriptRequest) returns (CreateTranscriptResponse)

/**
 * Create a single transcript
 * 
 * This RPC can be used to add out-of-band transcripts to the system,
 * e.g. to save a dictated report as a transcript.
 */
- (void)createTranscriptWithRequest:(CreateTranscriptRequest *)request handler:(void(^)(CreateTranscriptResponse *_Nullable response, NSError *_Nullable error))handler;

/**
 * Create a single transcript
 * 
 * This RPC can be used to add out-of-band transcripts to the system,
 * e.g. to save a dictated report as a transcript.
 */
- (GRPCProtoCall *)RPCToCreateTranscriptWithRequest:(CreateTranscriptRequest *)request handler:(void(^)(CreateTranscriptResponse *_Nullable response, NSError *_Nullable error))handler;


#pragma mark GetTranscript(GetTranscriptRequest) returns (Transcript)

/**
 * Request single transcript from the service.
 */
- (void)getTranscriptWithRequest:(GetTranscriptRequest *)request handler:(void(^)(Transcript *_Nullable response, NSError *_Nullable error))handler;

/**
 * Request single transcript from the service.
 */
- (GRPCProtoCall *)RPCToGetTranscriptWithRequest:(GetTranscriptRequest *)request handler:(void(^)(Transcript *_Nullable response, NSError *_Nullable error))handler;


#pragma mark UpdateTranscript(UpdateTranscriptRequest) returns (Transcript)

/**
 * Update any number of fields in an existing `Transcript` and return the
 * updated transcript.
 */
- (void)updateTranscriptWithRequest:(UpdateTranscriptRequest *)request handler:(void(^)(Transcript *_Nullable response, NSError *_Nullable error))handler;

/**
 * Update any number of fields in an existing `Transcript` and return the
 * updated transcript.
 */
- (GRPCProtoCall *)RPCToUpdateTranscriptWithRequest:(UpdateTranscriptRequest *)request handler:(void(^)(Transcript *_Nullable response, NSError *_Nullable error))handler;


#pragma mark WatchTranscripts(WatchTranscriptsRequest) returns (stream WatchTranscriptsResponse)

/**
 * Start watching for changes in transcripts.
 */
- (void)watchTranscriptsWithRequest:(WatchTranscriptsRequest *)request eventHandler:(void(^)(BOOL done, WatchTranscriptsResponse *_Nullable response, NSError *_Nullable error))eventHandler;

/**
 * Start watching for changes in transcripts.
 */
- (GRPCProtoCall *)RPCToWatchTranscriptsWithRequest:(WatchTranscriptsRequest *)request eventHandler:(void(^)(BOOL done, WatchTranscriptsResponse *_Nullable response, NSError *_Nullable error))eventHandler;


#pragma mark ListTranscripts(ListTranscriptsRequest) returns (ListTranscriptsResponse)

- (void)listTranscriptsWithRequest:(ListTranscriptsRequest *)request handler:(void(^)(ListTranscriptsResponse *_Nullable response, NSError *_Nullable error))handler;

- (GRPCProtoCall *)RPCToListTranscriptsWithRequest:(ListTranscriptsRequest *)request handler:(void(^)(ListTranscriptsResponse *_Nullable response, NSError *_Nullable error))handler;


#pragma mark ExportTranscript(ExportTranscriptRequest) returns (ExportTranscriptResponse)

/**
 * Export a transcript in a specific standard (or non-standard) format
 */
- (void)exportTranscriptWithRequest:(ExportTranscriptRequest *)request handler:(void(^)(ExportTranscriptResponse *_Nullable response, NSError *_Nullable error))handler;

/**
 * Export a transcript in a specific standard (or non-standard) format
 */
- (GRPCProtoCall *)RPCToExportTranscriptWithRequest:(ExportTranscriptRequest *)request handler:(void(^)(ExportTranscriptResponse *_Nullable response, NSError *_Nullable error))handler;


#pragma mark DeleteTranscript(DeleteTranscriptRequest) returns (Empty)

/**
 * Delete all versions of Transcript and recording if exists
 */
- (void)deleteTranscriptWithRequest:(DeleteTranscriptRequest *)request handler:(void(^)(GPBEmpty *_Nullable response, NSError *_Nullable error))handler;

/**
 * Delete all versions of Transcript and recording if exists
 */
- (GRPCProtoCall *)RPCToDeleteTranscriptWithRequest:(DeleteTranscriptRequest *)request handler:(void(^)(GPBEmpty *_Nullable response, NSError *_Nullable error))handler;


#pragma mark SubmitAlignmentJob(SubmitAlignmentJobRequest) returns (AlignmentJob)

/**
 * Submit transcript to be (re-)aligned
 */
- (void)submitAlignmentJobWithRequest:(SubmitAlignmentJobRequest *)request handler:(void(^)(AlignmentJob *_Nullable response, NSError *_Nullable error))handler;

/**
 * Submit transcript to be (re-)aligned
 */
- (GRPCProtoCall *)RPCToSubmitAlignmentJobWithRequest:(SubmitAlignmentJobRequest *)request handler:(void(^)(AlignmentJob *_Nullable response, NSError *_Nullable error))handler;


#pragma mark GetAlignmentJob(GetAlignmentJobRequest) returns (AlignmentJob)

/**
 * Get status of submitted alignment job
 */
- (void)getAlignmentJobWithRequest:(GetAlignmentJobRequest *)request handler:(void(^)(AlignmentJob *_Nullable response, NSError *_Nullable error))handler;

/**
 * Get status of submitted alignment job
 */
- (GRPCProtoCall *)RPCToGetAlignmentJobWithRequest:(GetAlignmentJobRequest *)request handler:(void(^)(AlignmentJob *_Nullable response, NSError *_Nullable error))handler;


#pragma mark CancelAlignmentJob(CancelAlignmentJobRequest) returns (AlignmentJob)

/**
 * Cancel a submitted alignment job
 */
- (void)cancelAlignmentJobWithRequest:(CancelAlignmentJobRequest *)request handler:(void(^)(AlignmentJob *_Nullable response, NSError *_Nullable error))handler;

/**
 * Cancel a submitted alignment job
 */
- (GRPCProtoCall *)RPCToCancelAlignmentJobWithRequest:(CancelAlignmentJobRequest *)request handler:(void(^)(AlignmentJob *_Nullable response, NSError *_Nullable error))handler;


#pragma mark WatchAlignmentJobs(WatchAlignmentJobsRequest) returns (stream WatchAlignmentJobsResponse)

/**
 * Start watching for changes in submitted alignment jobs.
 * 
 * The first successful response will contain all `jobs` that match
 * `WatchAlignmentJobsRequest.filter`. Subsequent responses will have
 * `update=true` and `jobs` will contain only updated jobs.
 */
- (void)watchAlignmentJobsWithRequest:(WatchAlignmentJobsRequest *)request eventHandler:(void(^)(BOOL done, WatchAlignmentJobsResponse *_Nullable response, NSError *_Nullable error))eventHandler;

/**
 * Start watching for changes in submitted alignment jobs.
 * 
 * The first successful response will contain all `jobs` that match
 * `WatchAlignmentJobsRequest.filter`. Subsequent responses will have
 * `update=true` and `jobs` will contain only updated jobs.
 */
- (GRPCProtoCall *)RPCToWatchAlignmentJobsWithRequest:(WatchAlignmentJobsRequest *)request eventHandler:(void(^)(BOOL done, WatchAlignmentJobsResponse *_Nullable response, NSError *_Nullable error))eventHandler;


#pragma mark ListAlignmentJobs(ListAlignmentJobsRequest) returns (ListAlignmentJobsResponse)

- (void)listAlignmentJobsWithRequest:(ListAlignmentJobsRequest *)request handler:(void(^)(ListAlignmentJobsResponse *_Nullable response, NSError *_Nullable error))handler;

- (GRPCProtoCall *)RPCToListAlignmentJobsWithRequest:(ListAlignmentJobsRequest *)request handler:(void(^)(ListAlignmentJobsResponse *_Nullable response, NSError *_Nullable error))handler;


@end


#if !defined(GPB_GRPC_PROTOCOL_ONLY) || !GPB_GRPC_PROTOCOL_ONLY
/**
 * Basic service implementation, over gRPC, that only does
 * marshalling and parsing.
 */
@interface TranscriptService : GRPCProtoService<TranscriptService>
- (instancetype)initWithHost:(NSString *)host NS_DESIGNATED_INITIALIZER;
+ (instancetype)serviceWithHost:(NSString *)host;
@end
#endif

NS_ASSUME_NONNULL_END

