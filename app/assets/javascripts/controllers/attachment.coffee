AttachmentController = ($scope, $upload) ->
  $scope.imageFor = (attachment) ->
    if attachment.image
      "https://s3-us-west-2.amazonaws.com/#{ $scope.bucket }/#{ attachment.small_attachment_uid }"
    else
      '/assets/rails.png'

  #
  $scope.upPosition = (index) ->
    tmp = $scope.attachments[index - 1]
    return  unless tmp

    $scope.attachments[index - 1] = $scope.attachments[index]
    $scope.attachments[index] = tmp

  #
  $scope.downPosition = (index) ->
    tmp = $scope.attachments[index + 1]
    return  unless tmp

    $scope.attachments[index + 1] = $scope.attachments[index]
    $scope.attachments[index] = tmp

  # Upload
  $scope.onFileSelect = ($files) ->
    $files.forEach( (file) ->
      console.log file
      $scope.upload = $upload.upload(
        url: '/attachments',
        data: {
          attachable_id: $scope.attachable_id,
          attachable_type: $scope.attachable_type,
          position: $scope.position
        },
        file: file
      )
      .progress( (event) ->
        console.log(event.total, event.loaded)
      )
      .success( (data, status, headers, config) ->
        console.log('Success', data)
      )
    )

# End of function

AttachmentController.$inject = ['$scope', '$upload']

myApp.controller('AttachmentController', AttachmentController)