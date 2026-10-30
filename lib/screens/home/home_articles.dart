class HomeArticle {
  const HomeArticle({
    required this.id,
    required this.title,
    required this.summary,
    required this.topic,
    required this.image,
    required this.body,
    required this.relatedIds,
  });

  final String id;
  final String title;
  final String summary;
  final String topic;
  final String image;
  final String body;
  final List<String> relatedIds;
}

const homeArticles = <HomeArticle>[
  HomeArticle(
    id: 'healthy-hair-routine',
    topic: 'MẸO CHĂM TÓC',
    title: '5 thói quen nhỏ giúp tóc khỏe hơn',
    summary: 'Giữ mái tóc mềm mượt từ những điều đơn giản mỗi ngày.',
    image: 'https://rebeccabeauty.co.uk/assets/img/services/salon/female-hairdresser-using-hairbrush-hair-dryer.jpg',
    body: 'Một mái tóc khỏe bắt đầu từ những thói quen nhẹ nhàng và đều đặn. Hãy chải tóc từ ngọn lên thân để gỡ rối mà không kéo căng chân tóc. Khi gội, dùng đầu ngón tay massage da đầu và xả sạch sản phẩm.\n\nThấm tóc bằng khăn mềm thay vì chà xát mạnh. Hạn chế nhiệt độ cao, dùng sản phẩm bảo vệ nhiệt khi sấy hoặc tạo kiểu. Cuối cùng, tỉa phần ngọn định kỳ giúp mái tóc trông gọn và khỏe hơn.\n\nChọn sản phẩm phù hợp với chất tóc và dành thời gian cho một liệu trình dưỡng sâu khi tóc khô xơ.',
    relatedIds: ['color-care', 'before-after-salon'],
  ),
  HomeArticle(
    id: 'choose-your-style',
    topic: 'CẢM HỨNG',
    title: 'Chọn kiểu tóc theo phong cách riêng',
    summary: 'Tìm kiểu tóc khiến bạn thấy tự tin và thoải mái nhất.',
    image: 'https://images.squarespace-cdn.com/content/v1/5eb6226f9c039e2519e85c06/860b39fa-b2c6-4e73-8e75-6f8b37bfcf82/Untitled%2Bdesign%2B%2890%29.png',
    body: 'Kiểu tóc phù hợp không chỉ theo xu hướng. Hãy bắt đầu từ thói quen hằng ngày: thời gian bạn muốn dành để tạo kiểu, môi trường làm việc và cảm giác muốn thể hiện.\n\nMang theo vài hình ảnh tham khảo khi tư vấn với stylist. Cùng trao đổi về độ dài, kết cấu tóc tự nhiên và cách chăm sóc tại nhà. Một thay đổi vừa phải như thêm layer, đổi ngôi hoặc tạo mái cũng có thể đem lại diện mạo mới mà vẫn dễ làm quen.\n\nHãy ưu tiên lựa chọn khiến bạn cảm thấy là chính mình.',
    relatedIds: ['face-shape-guide', 'hair-trends'],
  ),
  HomeArticle(
    id: 'color-care',
    topic: 'MÀU TÓC',
    title: 'Giữ màu tóc nhuộm bền đẹp',
    summary: 'Vài lưu ý sau khi nhuộm giúp màu tóc tươi lâu hơn.',
    image: 'https://luxvolosy.uz/assets/srv_haircut_styling.png',
    body: 'Sau khi nhuộm, hãy làm theo hướng dẫn chăm sóc của stylist và chọn dầu gội dịu nhẹ dành cho tóc nhuộm. Nước quá nóng có thể khiến tóc khô và màu phai nhanh, vì vậy nên gội bằng nước ấm vừa.\n\nDưỡng tóc thường xuyên, dùng sản phẩm bảo vệ nhiệt trước khi sấy và che chắn tóc khi tiếp xúc nắng lâu. Tần suất gội phù hợp tùy da đầu và lịch sinh hoạt; không cần cố kéo dài nếu da đầu khó chịu.\n\nNếu muốn dặm màu, hãy trao đổi với chuyên viên để chọn thời điểm và công thức phù hợp với nền tóc hiện tại.',
    relatedIds: ['healthy-hair-routine', 'before-after-salon'],
  ),
  HomeArticle(
    id: 'face-shape-guide',
    topic: 'TƯ VẤN KIỂU TÓC',
    title: 'Gợi ý kiểu tóc theo đường nét gương mặt',
    summary: 'Tham khảo cách dùng layer và mái để tạo sự cân đối.',
    image: 'https://www.shapesbrow.com/Hair%20Services.png',
    body: 'Các hướng dẫn theo dáng mặt chỉ nên dùng làm gợi ý ban đầu. Tỉ lệ gương mặt, đường chân tóc và độ dày tóc đều ảnh hưởng đến kết quả thực tế.\n\nNếu muốn tạo cảm giác mềm mại, có thể trao đổi về những lớp tóc ôm nhẹ quanh mặt hoặc phần mái dễ biến tấu. Với kiểu tóc ngắn, hãy hỏi stylist về độ dài phù hợp khi tóc khô và cách tóc ôm gáy.\n\nMột buổi tư vấn trực tiếp sẽ giúp điều chỉnh kiểu tham khảo theo chất tóc và phong cách riêng của bạn.',
    relatedIds: ['choose-your-style', 'hair-trends'],
  ),
  HomeArticle(
    id: 'before-after-salon',
    topic: 'CHĂM SÓC TÓC',
    title: 'Chuẩn bị trước và sau buổi làm tóc',
    summary: 'Giúp buổi hẹn tại salon thoải mái và đạt kết quả như mong muốn.',
    image: 'https://images.squarespace-cdn.com/content/v1/59c93f06f43b55ff86ce5691/1687376874339-5ID7PHI4X8658B8E2S92/salonriza-11.jpg',
    body: 'Trước buổi hẹn, lưu lại ảnh kiểu tóc bạn thích và ghi chú điều bạn muốn thay đổi. Hãy chia sẻ lịch sử nhuộm, uốn hoặc duỗi gần đây để stylist đánh giá nền tóc chính xác hơn.\n\nSau khi làm tóc, hỏi rõ cách gội, sấy và chăm sóc tại nhà. Với dịch vụ hóa chất, thời gian chờ trước lần gội tiếp theo có thể khác nhau tùy sản phẩm và tình trạng tóc.\n\nNếu tóc có dấu hiệu khô hoặc da đầu nhạy cảm, liên hệ salon để được hướng dẫn thay vì tự ý dùng nhiều sản phẩm cùng lúc.',
    relatedIds: ['healthy-hair-routine', 'color-care'],
  ),
  HomeArticle(
    id: 'hair-trends',
    topic: 'XU HƯỚNG',
    title: 'Những điểm nhấn tóc đang được yêu thích',
    summary:
        'Layer mềm, sóng tự nhiên và màu nâu ấm vẫn được nhiều người chọn.',
    image: 'https://robpeetoom.com/cdn/shop/articles/2025_RPUtrecht_ghd_event2626_278b323c-7ff7-48d9-9716-74198ecd48a8.jpg?v=1767620778',
    body: 'Những kiểu tóc có chuyển động tự nhiên tiếp tục được yêu thích vì dễ phối hợp với nhiều phong cách. Layer mềm giúp mái tóc trông có độ bay; sóng lơi tạo kết cấu mà không quá cầu kỳ.\n\nCác tông nâu ấm cũng là lựa chọn linh hoạt, nhưng màu lên thực tế còn phụ thuộc nền tóc và ánh sáng. Hãy trao đổi với stylist về khả năng lên màu, mức độ cần tẩy và cách duy trì.\n\nXu hướng là nguồn tham khảo; lựa chọn phù hợp nhất vẫn là kiểu tóc bạn có thể chăm sóc và yêu thích mỗi ngày.',
    relatedIds: ['choose-your-style', 'color-care'],
  ),
  HomeArticle(
    id: 'gentle-repair',
    topic: 'PHỤC HỒI',
    title: 'Chăm sóc mái tóc khô xơ nhẹ nhàng',
    summary:
        'Bắt đầu bằng dưỡng ẩm, giảm nhiệt và điều chỉnh thói quen tạo kiểu.',
    image: 'https://static.wixstatic.com/media/f5aeb7_839090ab16d743048b5aaa21d39dea84~mv2_d_5068_3379_s_4_2.jpg/v1/fill/w_1000%2Ch_667%2Cal_c%2Cq_85%2Cusm_0.66_1.00_0.01/f5aeb7_839090ab16d743048b5aaa21d39dea84~mv2_d_5068_3379_s_4_2.jpg',
    body: 'Khi tóc khô xơ, hãy giảm nhiệt tạo kiểu và dùng dầu xả ở phần thân, ngọn tóc. Mặt nạ dưỡng có thể bổ sung vào lịch chăm sóc tùy tình trạng tóc; dùng đúng lượng theo hướng dẫn trên sản phẩm.\n\nTránh chải mạnh khi tóc ướt vì tóc dễ bị kéo giãn. Dùng lược răng thưa và gỡ rối từ ngọn lên. Nếu tóc đã qua nhiều lần xử lý hóa chất, nên hỏi chuyên viên trước khi tiếp tục uốn hoặc nhuộm.\n\nChăm sóc đều đặn thường hữu ích hơn việc thử nhiều sản phẩm cùng lúc.',
    relatedIds: ['healthy-hair-routine', 'before-after-salon'],
  ),
];
