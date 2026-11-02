import 'package:flutter/material.dart';

/// Editorial care information owned by Home, not a shared service catalogue.
class HomeCareTreatment {
  const HomeCareTreatment({
    required this.id,
    required this.title,
    required this.introduction,
    required this.coverImageUrl,
    required this.imageSource,
    required this.accent,
    required this.suitableFor,
    required this.steps,
    required this.benefits,
    required this.aftercare,
  });

  final String id;
  final String title;
  final String introduction;
  final String coverImageUrl;
  final String imageSource;
  final Color accent;
  final List<String> suitableFor;
  final List<HomeCareStep> steps;
  final List<String> benefits;
  final List<String> aftercare;
}

class HomeCareStep {
  const HomeCareStep(this.title, this.description);

  final String title;
  final String description;
}

// General care references; no prices, timings or named products are assumed:
// https://www.aad.org/public/everyday-care/hair-scalp-care/hair/healthy-hair-tips
// https://www.aad.org/public/diseases/hair-loss/insider/stop-damage
// Both illustration photographs use https://www.pexels.com/license/
const deepRepairTreatment = HomeCareTreatment(
  id: 'deep-repair',
  title: 'Phục hồi chuyên sâu',
  introduction:
      'Một buổi chăm sóc tập trung vào thân và ngọn tóc đang khô ráp, khó gỡ rối '
      'hoặc thiếu độ bóng. Mục tiêu là làm mềm bề mặt tóc và hỗ trợ việc chải, '
      'sắp xếp mái tóc nhẹ nhàng hơn.\n\n'
      'Chất tóc và lịch sử nhuộm, uốn, duỗi cần được xem xét trước khi chọn cách '
      'chăm sóc. Thay vì áp dụng một công thức cho mọi mái tóc, hãy cùng chuyên '
      'viên xác định vùng tóc cần được chú ý và cảm giác bạn muốn cải thiện.',
  coverImageUrl: 'https://images.pexels.com/photos/3993451/pexels-photo-3993451.jpeg?auto=compress&cs=tinysrgb&w=1200',
  imageSource:
      'https://www.pexels.com/photo/woman-having-her-hair-rinse-3993451/',
  accent: Color(0xFFE5F0EB),
  suitableFor: [
    'Tóc khô xơ sau các lần tạo kiểu hoặc xử lý hóa chất.',
    'Thân và ngọn tóc thường rối, khó chải hoặc có cảm giác thô ráp.',
    'Người muốn được tư vấn cách chăm sóc riêng cho vùng tóc thiếu độ mềm.',
  ],
  steps: [
    HomeCareStep(
      'Trao đổi và quan sát chất tóc',
      'Chia sẻ những lần làm tóc gần đây và thói quen dùng nhiệt. Chuyên viên '
          'quan sát độ rối, bề mặt tóc và cùng bạn thống nhất mục tiêu chăm sóc.',
    ),
    HomeCareStep(
      'Làm sạch và chuẩn bị nhẹ nhàng',
      'Làm sạch da đầu, xả bọt qua thân tóc và tránh vò mạnh phần ngọn. '
          'Thấm bớt nước bằng khăn mềm để chuẩn bị cho bước dưỡng.',
    ),
    HomeCareStep(
      'Chăm sóc vùng thân và ngọn',
      'Chia tóc thành từng phần, phân bổ sản phẩm dưỡng được tư vấn vào vùng '
          'cần chăm sóc. Cách sử dụng và bước xả tuân theo hướng dẫn của sản phẩm.',
    ),
    HomeCareStep(
      'Gỡ rối và hoàn thiện',
      'Gỡ rối từng phần từ ngọn lên theo kết cấu tóc, hạn chế kéo căng. '
          'Làm khô nhẹ nhàng và tránh dùng nhiệt cao không cần thiết.',
    ),
    HomeCareStep(
      'Đánh giá và lên hướng chăm sóc tiếp theo',
      'Cảm nhận độ suôn khi chải và bề mặt tóc sau chăm sóc. Trao đổi những '
          'thói quen nên điều chỉnh để duy trì cảm giác mềm mại tại nhà.',
    ),
  ],
  benefits: [
    'Hướng tới cảm giác thân và ngọn tóc mềm hơn, bớt khô ráp.',
    'Hỗ trợ gỡ rối và chải tóc thuận tiện hơn.',
    'Mái tóc có thể trông gọn gàng và bóng hơn khi được hoàn thiện.',
    'Có hướng chăm sóc phù hợp với vùng tóc đang cần được chú ý.',
  ],
  aftercare: [
    'Dùng bước dưỡng phù hợp với chất tóc sau khi gội, chú ý phần thân và ngọn.',
    'Thấm tóc nhẹ bằng khăn mềm; hạn chế chà xát và tạo kiểu bằng nhiệt cao.',
    'Trao đổi lại với stylist trước khi tiếp tục nhuộm, uốn hoặc duỗi.',
  ],
);

const softMoistureTreatment = HomeCareTreatment(
  id: 'soft-moisture',
  title: 'Dưỡng tóc mềm mượt',
  introduction:
      'Chăm sóc hướng tới cảm giác mềm, nhẹ và dễ vào nếp trong sinh hoạt '
      'hằng ngày. Liệu trình chú trọng làm sạch vừa đủ và phân bổ bước dưỡng '
      'theo độ dày, kết cấu của tóc, để phần ngọn bớt khô mà mái tóc vẫn thoải mái.\n\n'
      'Khác với buổi phục hồi tập trung vào vùng tóc khô xơ, lựa chọn này '
      'ưu tiên sự suôn mượt và một thói quen chăm sóc đơn giản, dễ duy trì.',
  coverImageUrl: 'https://images.pexels.com/photos/7440054/pexels-photo-7440054.jpeg?auto=compress&cs=tinysrgb&w=1200',
  imageSource: 'https://www.pexels.com/photo/a-hair-dresser-servicing-a-customer-7440054/',
  accent: Color(0xFFF7E8E8),
  suitableFor: [
    'Tóc thường hoặc hơi khô ở ngọn, cần một bước chăm sóc nhẹ nhàng.',
    'Tóc mảnh dễ có cảm giác nặng khi dùng quá nhiều sản phẩm dưỡng.',
    'Người muốn mái tóc dễ chải, dễ sắp xếp trong thói quen hằng ngày.',
  ],
  steps: [
    HomeCareStep(
      'Lắng nghe thói quen hằng ngày',
      'Trao đổi cách gội, sấy và cảm giác tóc sau mỗi lần chăm sóc. Xác định '
          'vùng tóc cần làm mềm và mức độ nhẹ, thoáng mà bạn mong muốn.',
    ),
    HomeCareStep(
      'Làm sạch vừa đủ',
      'Làm sạch da đầu theo tình trạng thực tế, xả sạch và thấm nước nhẹ. '
          'Tránh chà xát hoặc kéo mạnh phần tóc dài khi chuẩn bị dưỡng.',
    ),
    HomeCareStep(
      'Dưỡng mềm theo chất tóc',
      'Điều chỉnh lượng dưỡng theo độ dày và vùng tóc khô. Với tóc mảnh, '
          'ưu tiên phần ngọn; với tóc khô, trao đổi thêm vùng thân tóc cần chăm sóc.',
    ),
    HomeCareStep(
      'Hoàn thiện tự nhiên và hướng dẫn duy trì',
      'Gỡ rối nhẹ nhàng theo kết cấu tóc, làm khô ở mức nhiệt phù hợp và '
          'hoàn thiện nếp tóc đơn giản. Trao đổi cách dùng dưỡng để dễ chăm sóc tại nhà.',
    ),
  ],
  benefits: [
    'Hỗ trợ cảm giác mềm mại và dễ chải hơn.',
    'Giúp mái tóc trông gọn và suôn khi được hoàn thiện.',
    'Hướng tới độ nhẹ phù hợp khi chọn lượng dưỡng theo chất tóc.',
    'Dễ kết hợp với thói quen chăm sóc tóc hằng ngày.',
  ],
  aftercare: [
    'Điều chỉnh lịch gội theo nhu cầu của da đầu và sinh hoạt của bạn.',
    'Dùng lượng dưỡng phù hợp, tránh tăng lượng chỉ để tạo cảm giác bóng ngay.',
    'Gỡ rối từ ngọn lên, hạn chế giật kéo và sấy ở nhiệt độ quá cao.',
  ],
);
