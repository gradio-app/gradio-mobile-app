import '../models/huggingface_space.dart';

class GradioDownloadInterceptor {
  static String generateInterceptorScript(HuggingFaceSpace space) {
    return '''
      (function() {
        console.log('🚀 Gradio Download Interceptor initialized for space: ${space.id}');

        function extractFilename(url, contentDisposition) {
          if (contentDisposition) {
            const filenameMatch = contentDisposition.match(/filename[^;=\\n]*=((['"]).*?\\2|[^;\\n]*)/);
            if (filenameMatch && filenameMatch[1]) {
              return filenameMatch[1].replace(/['"]/g, '');
            }
          }

          try {
            const urlPath = new URL(url).pathname;
            const filename = urlPath.split('/').pop();
            if (filename && filename.includes('.')) {
              return filename;
            }
          } catch (e) {
            console.log('Error parsing URL for filename:', e);
          }

          const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
          return `gradio_output_\${timestamp}`;
        }

        function getFileTypeFromUrl(url) {
          if (url.includes('image') || url.match(/\\.(jpg|jpeg|png|gif|webp|bmp|svg)(\$|\\?)/i)) {
            return 'image';
          }
          if (url.includes('audio') || url.match(/\\.(mp3|wav|ogg|aac|m4a|flac)(\$|\\?)/i)) {
            return 'audio';
          }
          if (url.includes('video') || url.match(/\\.(mp4|avi|mov|webm|mkv|flv)(\$|\\?)/i)) {
            return 'video';
          }
          if (url.match(/\\.(pdf|doc|docx|txt|rtf|md)(\$|\\?)/i)) {
            return 'document';
          }
          if (url.match(/\\.(json|csv|xml|yml|yaml)(\$|\\?)/i)) {
            return 'data';
          }
          return 'file';
        }

        async function convertBlobToBase64(blobUrl) {
          try {
            const response = await fetch(blobUrl);
            const blob = await response.blob();
            return new Promise((resolve) => {
              const reader = new FileReader();
              reader.onloadend = () => resolve(reader.result);
              reader.readAsDataURL(blob);
            });
          } catch (e) {
            console.log('Error converting blob to base64:', e);
            return null;
          }
        }

        async function handleDownload(url, filename, element) {
          console.log('🎯 Processing download:', url);

          let downloadData = {
            type: 'download_intercepted',
            space_id: '${space.id}',
            space_name: '${space.name}',
            file_url: url,
            file_name: filename,
            file_type: getFileTypeFromUrl(url),
            timestamp: Date.now(),
            is_blob: url.startsWith('blob:'),
            is_data_url: url.startsWith('data:')
          };

          if (url.startsWith('blob:')) {
            console.log('🔄 Converting blob URL to base64...');
            const base64Data = await convertBlobToBase64(url);
            if (base64Data) {
              downloadData.file_url = base64Data;
              downloadData.base64_data = base64Data;
              console.log('✅ Blob converted to base64 successfully');
            } else {
              console.log('❌ Failed to convert blob to base64');
              return;
            }
          }

          if (window.saveDownloadedFile) {
            console.log('📤 Sending download data to Flutter');
            window.saveDownloadedFile.postMessage(JSON.stringify(downloadData));
          } else {
            console.log('❌ Flutter download handler not available');
          }
        }

        document.addEventListener('click', function(event) {
          const target = event.target;
          const anchor = target.closest('a');

          if (anchor && anchor.href) {
            const href = anchor.href;

            if (href.includes('blob:') ||
                href.includes('data:') ||
                anchor.download ||
                anchor.hasAttribute('download')) {

              console.log('🎯 Download detected:', href);

              event.preventDefault();

              let filename = anchor.download || anchor.getAttribute('download') || extractFilename(href);

              if (!filename.includes('.')) {
                const fileType = getFileTypeFromUrl(href);
                const extensions = {
                  'image': '.png',
                  'audio': '.mp3',
                  'video': '.mp4',
                  'document': '.txt',
                  'data': '.json'
                };
                filename += extensions[fileType] || '.bin';
              }

              handleDownload(href, filename, anchor);
            }
          }
        });

        const originalCreateElement = document.createElement;
        document.createElement = function(tagName) {
          const element = originalCreateElement.apply(this, arguments);

          if (tagName.toLowerCase() === 'a') {
            const originalSetAttribute = element.setAttribute;
            element.setAttribute = function(name, value) {
              if (name === 'href' && (value.includes('blob:') || value.includes('data:'))) {
                console.log('🎯 Programmatic download detected:', value);

                element._isGradioDownload = true;
                element._downloadUrl = value;
              }
              return originalSetAttribute.apply(this, arguments);
            };

            const originalClick = element.click;
            element.click = function() {
              if (this._isGradioDownload && this._downloadUrl) {
                console.log('🎯 Programmatic download click intercepted');

                let filename = this.download || this.getAttribute('download') ||
                              extractFilename(this._downloadUrl);

                if (!filename.includes('.')) {
                  const fileType = getFileTypeFromUrl(this._downloadUrl);
                  const extensions = {
                    'image': '.png',
                    'audio': '.mp3',
                    'video': '.mp4',
                    'document': '.txt',
                    'data': '.json'
                  };
                  filename += extensions[fileType] || '.bin';
                }

                handleDownload(this._downloadUrl, filename, this);

                return false;
              }

              return originalClick.apply(this, arguments);
            };
          }

          return element;
        };

        const observer = new MutationObserver(function(mutations) {
          mutations.forEach(function(mutation) {
            mutation.addedNodes.forEach(function(node) {
              if (node.nodeType === 1) {
                const downloadElements = node.querySelectorAll ?
                  node.querySelectorAll('a[download], button[data-download], .download-btn') :
                  [];

                downloadElements.forEach(function(element) {
                  if (!element._downloadListenerAdded) {
                    element.addEventListener('click', function(e) {
                      console.log('🎯 New download button clicked:', element);
                    });
                    element._downloadListenerAdded = true;
                  }
                });
              }
            });
          });
        });

        observer.observe(document.body, {
          childList: true,
          subtree: true
        });

        const originalFetch = window.fetch;
        window.fetch = async function(...args) {
          const response = await originalFetch.apply(this, args);

          if (response.headers.get('content-disposition') ||
              response.headers.get('content-type')?.startsWith('application/octet-stream')) {

            console.log('🎯 Fetch download detected:', args[0]);

            const contentDisposition = response.headers.get('content-disposition');
            const filename = extractFilename(args[0], contentDisposition);

            const clonedResponse = response.clone();

            try {
              const blob = await clonedResponse.blob();
              const blobUrl = URL.createObjectURL(blob);

              await handleDownload(blobUrl, filename, null);
            } catch (e) {
              console.log('Error processing fetch download:', e);
            }
          }

          return response;
        };

        console.log('✅ Gradio Download Interceptor setup complete');
      })();
    ''';
  }
}