import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

class TransferProgressWidget extends StatelessWidget {
  final String fileName;
  final String deviceName;
  final double progress; // 0 to 1
  final double speedMBps;
  final int totalFileSize; // in bytes
  final bool isUpload;
  final VoidCallback? onCancel;

  const TransferProgressWidget({
    super.key,
    required this.fileName,
    required this.deviceName,
    required this.progress,
    required this.speedMBps,
    required this.totalFileSize,
    required this.isUpload,
    this.onCancel,
  });

  String get _formattedSize {
    if (totalFileSize < 1024) return '$totalFileSize B';
    if (totalFileSize < 1024 * 1024) {
      return '${(totalFileSize / 1024).toStringAsFixed(2)} KB';
    }
    if (totalFileSize < 1024 * 1024 * 1024) {
      return '${(totalFileSize / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(totalFileSize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String get _timeRemaining {
    if (speedMBps <= 0) return 'Calculating...';
    final bytesRemaining = totalFileSize * (1 - progress);
    final secondsRemaining = bytesRemaining / (speedMBps * 1024 * 1024);

    if (secondsRemaining < 60) {
      return '${secondsRemaining.toStringAsFixed(0)}s left';
    }
    final minutes = (secondsRemaining / 60).toStringAsFixed(1);
    return '${minutes}m left';
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (progress * 100).toStringAsFixed(0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isUpload ? Colors.blue : Colors.purple).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isUpload ? Icons.upload_rounded : Icons.download_rounded,
                color: isUpload ? Colors.blue : Colors.purple,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            
            // Title
            Text(
              isUpload ? 'Sending File' : 'Receiving File',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isUpload ? 'To $deviceName' : 'From $deviceName',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),

            // Progress Indicator
            SizedBox(
              width: 150,
              height: 150,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 10,
                      strokeCap: StrokeCap.round,
                      backgroundColor: Colors.grey.shade100,
                      color: isUpload ? Colors.blue : Colors.purple,
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$percentage%',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        _formattedSize,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // File Name Container
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                fileName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Stats row
            Row(
              children: [
                _buildStatColumn(Icons.speed_rounded, '${speedMBps.toStringAsFixed(1)} MB/s', 'Speed'),
                Container(height: 30, width: 1, color: Colors.grey.shade200),
                _buildStatColumn(Icons.timer_outlined, _timeRemaining, 'Remaining'),
              ],
            ),
            const SizedBox(height: 24),

            // Cancel Button
            if (onCancel != null)
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: onCancel,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    backgroundColor: Colors.red.shade50.withOpacity(0.5),
                  ),
                  child: const Text(
                    'Cancel Transfer',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade400),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class CompletionDialog extends StatelessWidget {
  final String fileName;
  final String deviceName;
  final bool isSuccess;
  final String? errorMessage;
  final String? filePath;
  final VoidCallback onDone;

  const CompletionDialog({
    super.key,
    required this.fileName,
    required this.deviceName,
    required this.isSuccess,
    this.errorMessage,
    this.filePath,
    required this.onDone,
  });

  void _openFile() {
    if (filePath != null) {
      OpenFilex.open(filePath!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status Icon
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                color: (isSuccess ? Colors.green : Colors.red).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
                size: 48,
                color: isSuccess ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              isSuccess ? 'All set!' : 'Oops!',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSuccess 
                ? 'File transferred successfully' 
                : 'Transfer failed. Please try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 24),
            
            // File Preview Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.insert_drive_file_rounded, color: Colors.blue.shade300),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            
            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ],
            
            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                if (isSuccess && filePath != null)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ElevatedButton(
                        onPressed: _openFile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Open', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDone,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey.shade200),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
