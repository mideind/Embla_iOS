#if !defined(GPB_GRPC_PROTOCOL_ONLY) || !GPB_GRPC_PROTOCOL_ONLY
#import "lr/transcript/v1alpha1/Transcript.pbrpc.h"
#import "lr/transcript/v1alpha1/Transcript.pbobjc.h"
#import <ProtoRPC/ProtoRPC.h>
#import <RxLibrary/GRXWriter+Immediate.h>

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

@implementation TranscriptService

// Designated initializer
- (instancetype)initWithHost:(NSString *)host {
  self = [super initWithHost:host
                 packageName:@"lr.transcript.v1alpha1"
                 serviceName:@"TranscriptService"];
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

#pragma mark SubmitTranscriptJob(SubmitTranscriptJobRequest) returns (TranscriptJob)

/**
 * Submit audio or video to be transcribed
 */
- (void)submitTranscriptJobWithRequest:(SubmitTranscriptJobRequest *)request handler:(void(^)(TranscriptJob *_Nullable response, NSError *_Nullable error))handler{
  [[self RPCToSubmitTranscriptJobWithRequest:request handler:handler] start];
}
// Returns a not-yet-started RPC object.
/**
 * Submit audio or video to be transcribed
 */
- (GRPCProtoCall *)RPCToSubmitTranscriptJobWithRequest:(SubmitTranscriptJobRequest *)request handler:(void(^)(TranscriptJob *_Nullable response, NSError *_Nullable error))handler{
  return [self RPCToMethod:@"SubmitTranscriptJob"
            requestsWriter:[GRXWriter writerWithValue:request]
             responseClass:[TranscriptJob class]
        responsesWriteable:[GRXWriteable writeableWithSingleHandler:handler]];
}
#pragma mark GetTranscriptJob(GetTranscriptJobRequest) returns (TranscriptJob)

/**
 * Get status of submitted transcript job
 */
- (void)getTranscriptJobWithRequest:(GetTranscriptJobRequest *)request handler:(void(^)(TranscriptJob *_Nullable response, NSError *_Nullable error))handler{
  [[self RPCToGetTranscriptJobWithRequest:request handler:handler] start];
}
// Returns a not-yet-started RPC object.
/**
 * Get status of submitted transcript job
 */
- (GRPCProtoCall *)RPCToGetTranscriptJobWithRequest:(GetTranscriptJobRequest *)request handler:(void(^)(TranscriptJob *_Nullable response, NSError *_Nullable error))handler{
  return [self RPCToMethod:@"GetTranscriptJob"
            requestsWriter:[GRXWriter writerWithValue:request]
             responseClass:[TranscriptJob class]
        responsesWriteable:[GRXWriteable writeableWithSingleHandler:handler]];
}
#pragma mark WatchTranscriptJobs(WatchTranscriptJobsRequest) returns (stream WatchTranscriptJobsResponse)

/**
 * Start watching for changes in submitted transcription jobs.
 * 
 * The first successful response will contain all `jobs` that match
 * `WatchTranscriptJobsRequest.filter`. Subsequent responses will have
 * `update=true` and `jobs` will contain only updated jobs.
 */
- (void)watchTranscriptJobsWithRequest:(WatchTranscriptJobsRequest *)request eventHandler:(void(^)(BOOL done, WatchTranscriptJobsResponse *_Nullable response, NSError *_Nullable error))eventHandler{
  [[self RPCToWatchTranscriptJobsWithRequest:request eventHandler:eventHandler] start];
}
// Returns a not-yet-started RPC object.
/**
 * Start watching for changes in submitted transcription jobs.
 * 
 * The first successful response will contain all `jobs` that match
 * `WatchTranscriptJobsRequest.filter`. Subsequent responses will have
 * `update=true` and `jobs` will contain only updated jobs.
 */
- (GRPCProtoCall *)RPCToWatchTranscriptJobsWithRequest:(WatchTranscriptJobsRequest *)request eventHandler:(void(^)(BOOL done, WatchTranscriptJobsResponse *_Nullable response, NSError *_Nullable error))eventHandler{
  return [self RPCToMethod:@"WatchTranscriptJobs"
            requestsWriter:[GRXWriter writerWithValue:request]
             responseClass:[WatchTranscriptJobsResponse class]
        responsesWriteable:[GRXWriteable writeableWithEventHandler:eventHandler]];
}
#pragma mark ListTranscriptJobs(ListTranscriptJobsRequest) returns (ListTranscriptJobsResponse)

- (void)listTranscriptJobsWithRequest:(ListTranscriptJobsRequest *)request handler:(void(^)(ListTranscriptJobsResponse *_Nullable response, NSError *_Nullable error))handler{
  [[self RPCToListTranscriptJobsWithRequest:request handler:handler] start];
}
// Returns a not-yet-started RPC object.
- (GRPCProtoCall *)RPCToListTranscriptJobsWithRequest:(ListTranscriptJobsRequest *)request handler:(void(^)(ListTranscriptJobsResponse *_Nullable response, NSError *_Nullable error))handler{
  return [self RPCToMethod:@"ListTranscriptJobs"
            requestsWriter:[GRXWriter writerWithValue:request]
             responseClass:[ListTranscriptJobsResponse class]
        responsesWriteable:[GRXWriteable writeableWithSingleHandler:handler]];
}
#pragma mark CreateTranscript(CreateTranscriptRequest) returns (CreateTranscriptResponse)

/**
 * Create a single transcript
 * 
 * This RPC can be used to add out-of-band transcripts to the system,
 * e.g. to save a dictated report as a transcript.
 */
- (void)createTranscriptWithRequest:(CreateTranscriptRequest *)request handler:(void(^)(CreateTranscriptResponse *_Nullable response, NSError *_Nullable error))handler{
  [[self RPCToCreateTranscriptWithRequest:request handler:handler] start];
}
// Returns a not-yet-started RPC object.
/**
 * Create a single transcript
 * 
 * This RPC can be used to add out-of-band transcripts to the system,
 * e.g. to save a dictated report as a transcript.
 */
- (GRPCProtoCall *)RPCToCreateTranscriptWithRequest:(CreateTranscriptRequest *)request handler:(void(^)(CreateTranscriptResponse *_Nullable response, NSError *_Nullable error))handler{
  return [self RPCToMethod:@"CreateTranscript"
            requestsWriter:[GRXWriter writerWithValue:request]
             responseClass:[CreateTranscriptResponse class]
        responsesWriteable:[GRXWriteable writeableWithSingleHandler:handler]];
}
#pragma mark GetTranscript(GetTranscriptRequest) returns (Transcript)

/**
 * Request single transcript from the service.
 */
- (void)getTranscriptWithRequest:(GetTranscriptRequest *)request handler:(void(^)(Transcript *_Nullable response, NSError *_Nullable error))handler{
  [[self RPCToGetTranscriptWithRequest:request handler:handler] start];
}
// Returns a not-yet-started RPC object.
/**
 * Request single transcript from the service.
 */
- (GRPCProtoCall *)RPCToGetTranscriptWithRequest:(GetTranscriptRequest *)request handler:(void(^)(Transcript *_Nullable response, NSError *_Nullable error))handler{
  return [self RPCToMethod:@"GetTranscript"
            requestsWriter:[GRXWriter writerWithValue:request]
             responseClass:[Transcript class]
        responsesWriteable:[GRXWriteable writeableWithSingleHandler:handler]];
}
#pragma mark UpdateTranscript(UpdateTranscriptRequest) returns (Transcript)

/**
 * Update any number of fields in an existing `Transcript` and return the
 * updated transcript.
 */
- (void)updateTranscriptWithRequest:(UpdateTranscriptRequest *)request handler:(void(^)(Transcript *_Nullable response, NSError *_Nullable error))handler{
  [[self RPCToUpdateTranscriptWithRequest:request handler:handler] start];
}
// Returns a not-yet-started RPC object.
/**
 * Update any number of fields in an existing `Transcript` and return the
 * updated transcript.
 */
- (GRPCProtoCall *)RPCToUpdateTranscriptWithRequest:(UpdateTranscriptRequest *)request handler:(void(^)(Transcript *_Nullable response, NSError *_Nullable error))handler{
  return [self RPCToMethod:@"UpdateTranscript"
            requestsWriter:[GRXWriter writerWithValue:request]
             responseClass:[Transcript class]
        responsesWriteable:[GRXWriteable writeableWithSingleHandler:handler]];
}
#pragma mark WatchTranscripts(WatchTranscriptsRequest) returns (stream WatchTranscriptsResponse)

/**
 * Start watching for changes in transcripts.
 */
- (void)watchTranscriptsWithRequest:(WatchTranscriptsRequest *)request eventHandler:(void(^)(BOOL done, WatchTranscriptsResponse *_Nullable response, NSError *_Nullable error))eventHandler{
  [[self RPCToWatchTranscriptsWithRequest:request eventHandler:eventHandler] start];
}
// Returns a not-yet-started RPC object.
/**
 * Start watching for changes in transcripts.
 */
- (GRPCProtoCall *)RPCToWatchTranscriptsWithRequest:(WatchTranscriptsRequest *)request eventHandler:(void(^)(BOOL done, WatchTranscriptsResponse *_Nullable response, NSError *_Nullable error))eventHandler{
  return [self RPCToMethod:@"WatchTranscripts"
            requestsWriter:[GRXWriter writerWithValue:request]
             responseClass:[WatchTranscriptsResponse class]
        responsesWriteable:[GRXWriteable writeableWithEventHandler:eventHandler]];
}
#pragma mark ListTranscripts(ListTranscriptsRequest) returns (ListTranscriptsResponse)

- (void)listTranscriptsWithRequest:(ListTranscriptsRequest *)request handler:(void(^)(ListTranscriptsResponse *_Nullable response, NSError *_Nullable error))handler{
  [[self RPCToListTranscriptsWithRequest:request handler:handler] start];
}
// Returns a not-yet-started RPC object.
- (GRPCProtoCall *)RPCToListTranscriptsWithRequest:(ListTranscriptsRequest *)request handler:(void(^)(ListTranscriptsResponse *_Nullable response, NSError *_Nullable error))handler{
  return [self RPCToMethod:@"ListTranscripts"
            requestsWriter:[GRXWriter writerWithValue:request]
             responseClass:[ListTranscriptsResponse class]
        responsesWriteable:[GRXWriteable writeableWithSingleHandler:handler]];
}
#pragma mark ExportTranscript(ExportTranscriptRequest) returns (ExportTranscriptResponse)

/**
 * Export a transcript in a specific standard (or non-standard) format
 */
- (void)exportTranscriptWithRequest:(ExportTranscriptRequest *)request handler:(void(^)(ExportTranscriptResponse *_Nullable response, NSError *_Nullable error))handler{
  [[self RPCToExportTranscriptWithRequest:request handler:handler] start];
}
// Returns a not-yet-started RPC object.
/**
 * Export a transcript in a specific standard (or non-standard) format
 */
- (GRPCProtoCall *)RPCToExportTranscriptWithRequest:(ExportTranscriptRequest *)request handler:(void(^)(ExportTranscriptResponse *_Nullable response, NSError *_Nullable error))handler{
  return [self RPCToMethod:@"ExportTranscript"
            requestsWriter:[GRXWriter writerWithValue:request]
             responseClass:[ExportTranscriptResponse class]
        responsesWriteable:[GRXWriteable writeableWithSingleHandler:handler]];
}
#pragma mark DeleteTranscript(DeleteTranscriptRequest) returns (Empty)

/**
 * Delete all versions of Transcript and recording if exists
 */
- (void)deleteTranscriptWithRequest:(DeleteTranscriptRequest *)request handler:(void(^)(GPBEmpty *_Nullable response, NSError *_Nullable error))handler{
  [[self RPCToDeleteTranscriptWithRequest:request handler:handler] start];
}
// Returns a not-yet-started RPC object.
/**
 * Delete all versions of Transcript and recording if exists
 */
- (GRPCProtoCall *)RPCToDeleteTranscriptWithRequest:(DeleteTranscriptRequest *)request handler:(void(^)(GPBEmpty *_Nullable response, NSError *_Nullable error))handler{
  return [self RPCToMethod:@"DeleteTranscript"
            requestsWriter:[GRXWriter writerWithValue:request]
             responseClass:[GPBEmpty class]
        responsesWriteable:[GRXWriteable writeableWithSingleHandler:handler]];
}
#pragma mark SubmitAlignmentJob(SubmitAlignmentJobRequest) returns (AlignmentJob)

/**
 * Submit transcript to be (re-)aligned
 */
- (void)submitAlignmentJobWithRequest:(SubmitAlignmentJobRequest *)request handler:(void(^)(AlignmentJob *_Nullable response, NSError *_Nullable error))handler{
  [[self RPCToSubmitAlignmentJobWithRequest:request handler:handler] start];
}
// Returns a not-yet-started RPC object.
/**
 * Submit transcript to be (re-)aligned
 */
- (GRPCProtoCall *)RPCToSubmitAlignmentJobWithRequest:(SubmitAlignmentJobRequest *)request handler:(void(^)(AlignmentJob *_Nullable response, NSError *_Nullable error))handler{
  return [self RPCToMethod:@"SubmitAlignmentJob"
            requestsWriter:[GRXWriter writerWithValue:request]
             responseClass:[AlignmentJob class]
        responsesWriteable:[GRXWriteable writeableWithSingleHandler:handler]];
}
#pragma mark GetAlignmentJob(GetAlignmentJobRequest) returns (AlignmentJob)

/**
 * Get status of submitted alignment job
 */
- (void)getAlignmentJobWithRequest:(GetAlignmentJobRequest *)request handler:(void(^)(AlignmentJob *_Nullable response, NSError *_Nullable error))handler{
  [[self RPCToGetAlignmentJobWithRequest:request handler:handler] start];
}
// Returns a not-yet-started RPC object.
/**
 * Get status of submitted alignment job
 */
- (GRPCProtoCall *)RPCToGetAlignmentJobWithRequest:(GetAlignmentJobRequest *)request handler:(void(^)(AlignmentJob *_Nullable response, NSError *_Nullable error))handler{
  return [self RPCToMethod:@"GetAlignmentJob"
            requestsWriter:[GRXWriter writerWithValue:request]
             responseClass:[AlignmentJob class]
        responsesWriteable:[GRXWriteable writeableWithSingleHandler:handler]];
}
#pragma mark CancelAlignmentJob(CancelAlignmentJobRequest) returns (AlignmentJob)

/**
 * Cancel a submitted alignment job
 */
- (void)cancelAlignmentJobWithRequest:(CancelAlignmentJobRequest *)request handler:(void(^)(AlignmentJob *_Nullable response, NSError *_Nullable error))handler{
  [[self RPCToCancelAlignmentJobWithRequest:request handler:handler] start];
}
// Returns a not-yet-started RPC object.
/**
 * Cancel a submitted alignment job
 */
- (GRPCProtoCall *)RPCToCancelAlignmentJobWithRequest:(CancelAlignmentJobRequest *)request handler:(void(^)(AlignmentJob *_Nullable response, NSError *_Nullable error))handler{
  return [self RPCToMethod:@"CancelAlignmentJob"
            requestsWriter:[GRXWriter writerWithValue:request]
             responseClass:[AlignmentJob class]
        responsesWriteable:[GRXWriteable writeableWithSingleHandler:handler]];
}
#pragma mark WatchAlignmentJobs(WatchAlignmentJobsRequest) returns (stream WatchAlignmentJobsResponse)

/**
 * Start watching for changes in submitted alignment jobs.
 * 
 * The first successful response will contain all `jobs` that match
 * `WatchAlignmentJobsRequest.filter`. Subsequent responses will have
 * `update=true` and `jobs` will contain only updated jobs.
 */
- (void)watchAlignmentJobsWithRequest:(WatchAlignmentJobsRequest *)request eventHandler:(void(^)(BOOL done, WatchAlignmentJobsResponse *_Nullable response, NSError *_Nullable error))eventHandler{
  [[self RPCToWatchAlignmentJobsWithRequest:request eventHandler:eventHandler] start];
}
// Returns a not-yet-started RPC object.
/**
 * Start watching for changes in submitted alignment jobs.
 * 
 * The first successful response will contain all `jobs` that match
 * `WatchAlignmentJobsRequest.filter`. Subsequent responses will have
 * `update=true` and `jobs` will contain only updated jobs.
 */
- (GRPCProtoCall *)RPCToWatchAlignmentJobsWithRequest:(WatchAlignmentJobsRequest *)request eventHandler:(void(^)(BOOL done, WatchAlignmentJobsResponse *_Nullable response, NSError *_Nullable error))eventHandler{
  return [self RPCToMethod:@"WatchAlignmentJobs"
            requestsWriter:[GRXWriter writerWithValue:request]
             responseClass:[WatchAlignmentJobsResponse class]
        responsesWriteable:[GRXWriteable writeableWithEventHandler:eventHandler]];
}
#pragma mark ListAlignmentJobs(ListAlignmentJobsRequest) returns (ListAlignmentJobsResponse)

- (void)listAlignmentJobsWithRequest:(ListAlignmentJobsRequest *)request handler:(void(^)(ListAlignmentJobsResponse *_Nullable response, NSError *_Nullable error))handler{
  [[self RPCToListAlignmentJobsWithRequest:request handler:handler] start];
}
// Returns a not-yet-started RPC object.
- (GRPCProtoCall *)RPCToListAlignmentJobsWithRequest:(ListAlignmentJobsRequest *)request handler:(void(^)(ListAlignmentJobsResponse *_Nullable response, NSError *_Nullable error))handler{
  return [self RPCToMethod:@"ListAlignmentJobs"
            requestsWriter:[GRXWriter writerWithValue:request]
             responseClass:[ListAlignmentJobsResponse class]
        responsesWriteable:[GRXWriteable writeableWithSingleHandler:handler]];
}
@end
#endif
