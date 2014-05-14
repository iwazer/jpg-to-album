# -*- coding: utf-8 -*-
class MainViewController < UIViewController
  extend IB

  outlet :src_dir
  outlet :message

  def viewDidLoad
    super
    @dir_name = @src_dir.text
  end

  def execute sender
    @resource_path = @dir_name.resource_path
    unless @resource_path
      usage
      return
    end
    @urls = Dir.glob(File.join("work".resource_path, "*.[Jj][Pp][Gg]")).map(&:fileurl)
    if @urls.empty?
      usage
      return
    end

    @message.text = ""
    @library = ALAssetsLibrary.alloc.init
    @finished = []
    @urls.each do |url|
      image_src = CGImageSourceCreateWithURL(url, nil)
      metadata = CGImageSourceCopyPropertiesAtIndex(image_src, 0, nil)
      image = UIImage.imageWithData(NSData.dataWithContentsOfURL(url)).CGImage
      write_to_saved_photos_album(url, image, metadata)
    end
  end

  def write_to_saved_photos_album url, image, metadata
    @library.writeImageToSavedPhotosAlbum(image, metadata:metadata,
      completionBlock:->(assetURL, error) {
        if assetURL
          @finished << assetURL
          append_message("success: #{File.basename(url.absoluteString)}")
          if @finished.length == @urls.length
            append_message("追加終了")
          end
        else
          if error && error.code == ALAssetsLibraryWriteBusyError
            sleep 0.1
            write_to_saved_photos_album(url, image, metadata)
          end
        end
      })
  end

  def delete_all sender
    @message.text = ""
    @library = ALAssetsLibrary.alloc.init

    enumration_block = ->(group, stop) {
      return unless group
      group.setAssetsFilter(ALAssetsFilter.allPhotos)

      @num = 0
      @fin = 0
      group.enumerateAssetsUsingBlock(-> (alAsset, index, stop) {
          if alAsset && alAsset.editable?
            @num += 1
          end          
        })

      group.enumerateAssetsUsingBlock(-> (alAsset, index, stop) {
          if alAsset && alAsset.editable?
            NSLog("delete %@", alAsset)
            delete_image alAsset
          end
        })
    }
      
    @library.enumerateGroupsWithTypes(ALAssetsGroupSavedPhotos,
      usingBlock: enumration_block,
      failureBlock: -> (error) {
        puts "No groups"
      })
  end

  def delete_image asset
    asset.setImageData(nil, metadata:nil, completionBlock:->(assetURL,error){
        if error && error.code == ALAssetsLibraryWriteBusyError
          sleep 0.1
          delete_image(asset)
        else
          @fin += 1
        end
        if @num == @fin
          append_message("削除終了")
        end
      })
  end

  def usage
    append_message("resourceディレクトリに#{@dir_name}を作成しJPEGファイルを置いてビルドしてください。")
  end

  def append_message str
    Dispatch::Queue.main.async {
      s = @message.text
      s += "\n" unless s.empty?
      @message.text = s + str
      bottomOffset = [0, @message.contentSize.height - @message.bounds.size.height]
      @message.setContentOffset(bottomOffset, animated:false)
    }
  end
end
