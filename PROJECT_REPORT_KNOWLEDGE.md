# Knowledge Base Báo Cáo Công Nghệ Phần Mềm

> Tài liệu này được xây dựng dựa trên việc phân tích mã nguồn, cấu trúc thư mục, lược đồ cơ sở dữ liệu, tuyến đường, mô hình, bộ điều khiển và các dịch vụ nghiệp vụ của dự án `dn-ruby-naitei-2025_e-learning-system`. Mục tiêu của tài liệu là làm nguồn tri thức đầu vào để viết báo cáo đồ án môn Công nghệ Phần mềm theo hướng phân tích nghiệp vụ, thiết kế hệ thống và quy trình phát triển phần mềm.

> Một số nhận định trong tài liệu là suy luận hợp lý từ mã nguồn hiện có, đặc biệt khi dự án không có tài liệu đặc tả nghiệp vụ chính thức.

## 1. Tổng Quan Dự Án

### 1.1. Tên hệ thống

Hệ thống được phân tích là một nền tảng học trực tuyến có tên trong kho mã nguồn là `dn-ruby-naitei-2025_e-learning-system`. Có thể đặt tên báo cáo là **Hệ thống E-Learning đa vai trò hỗ trợ học tập trực tuyến, quản lý khóa học và đào tạo doanh nghiệp**.

### 1.2. Mục tiêu xây dựng

Mục tiêu của hệ thống là xây dựng một nền tảng học trực tuyến cho phép nhiều nhóm người dùng cùng tham gia vào quá trình đào tạo. Học viên có thể tìm kiếm, mua và học khóa học. Giảng viên có thể tạo nội dung, quản lý học viên và theo dõi doanh thu. Quản trị viên có thể kiểm soát chất lượng khóa học, quản lý dữ liệu hệ thống và giám sát hoạt động kinh doanh. Doanh nghiệp có thể mua giấy phép học tập cho nhân viên và theo dõi hiệu quả đào tạo nội bộ.

Điểm đáng chú ý của dự án là hệ thống không chỉ dừng ở chức năng học trực tuyến cơ bản, mà còn mở rộng sang các nghiệp vụ như gợi ý khóa học, kế hoạch học tập cá nhân, chứng chỉ, mã giảm giá, thanh toán trực tuyến, ví doanh thu, yêu cầu rút tiền và cổng đào tạo doanh nghiệp.

### 1.3. Bài toán cần giải quyết

Trong mô hình đào tạo truyền thống hoặc các hệ thống học trực tuyến đơn giản, người học thường gặp khó khăn trong việc tìm khóa học phù hợp, theo dõi tiến độ, duy trì động lực và nhận được xác nhận sau khi hoàn thành khóa học. Giảng viên gặp khó khăn trong việc quản lý nội dung, kiểm tra năng lực học viên, theo dõi doanh thu và tương tác với cộng đồng học viên. Doanh nghiệp lại cần một cơ chế mua khóa học số lượng lớn, phân phối cho nhân viên và giám sát quá trình đào tạo.

Hệ thống giải quyết các vấn đề trên bằng cách cung cấp một nền tảng thống nhất, trong đó hoạt động học tập, thương mại điện tử, quản lý nội dung, phân quyền, báo cáo và đào tạo doanh nghiệp được tích hợp trong cùng một ứng dụng.

### 1.4. Đối tượng sử dụng

Các đối tượng sử dụng chính gồm khách chưa đăng nhập, học viên, giảng viên, quản trị viên, quản trị doanh nghiệp và nhân viên doanh nghiệp. Mỗi nhóm có mục tiêu sử dụng khác nhau, vì vậy hệ thống được thiết kế theo mô hình đa vai trò. Việc tách vai trò giúp đảm bảo mỗi người dùng chỉ truy cập đúng phạm vi nghiệp vụ của mình, đồng thời làm rõ trách nhiệm trong quy trình vận hành.

### 1.5. Phạm vi hệ thống

Phạm vi hệ thống bao gồm quản lý tài khoản, xác thực, phân quyền, quản lý danh mục khóa học, quản lý khóa học, bài học, câu hỏi, bài kiểm tra, đăng ký khóa học, thanh toán, giỏ hàng, danh sách yêu thích, đánh giá, bình luận, thảo luận, ghi chú cá nhân, theo dõi tiến độ học tập, cấp chứng chỉ, gợi ý khóa học, lập kế hoạch học tập, quản lý doanh thu, quản lý giảng viên, quản lý doanh nghiệp, mua và phân phối giấy phép học tập.

Các chức năng như trợ lý trí tuệ nhân tạo, học thích ứng nâng cao hoặc báo cáo phân tích chuyên sâu có thể được xem là hướng phát triển tiếp theo, tuy một số nền tảng dữ liệu cho các chức năng này đã xuất hiện trong mã nguồn.

## 2. Phân Tích Nghiệp Vụ

### 2.1. Bài toán nghiệp vụ

Hệ thống hướng đến bài toán kết nối ba nhóm lợi ích chính trong lĩnh vực học trực tuyến: người học cần tiếp cận tri thức thuận tiện; người dạy cần công cụ phân phối nội dung và tạo doanh thu; đơn vị quản lý cần kiểm soát chất lượng, vận hành thanh toán và đảm bảo trải nghiệm sử dụng.

Đối với học viên, vấn đề chính là quá trình học trực tuyến dễ bị rời rạc. Người học cần biết mình đang học đến đâu, cần học gì tiếp theo, có thể ghi chú, làm bài kiểm tra, xem lại kết quả và nhận chứng chỉ khi hoàn thành. Hệ thống giải quyết bằng cách lưu tiến độ học tập, cung cấp kế hoạch học, mục tiêu học tập, chuỗi ngày học liên tục, ghi chú cá nhân và chứng chỉ.

Đối với giảng viên, vấn đề là cần một quy trình chuẩn để tạo khóa học, tổ chức nội dung thành chương và bài học, tạo bài kiểm tra, gửi khóa học cho quản trị viên duyệt, theo dõi học viên và nhận doanh thu. Hệ thống giải quyết bằng cổng giảng viên, quản lý khóa học theo trạng thái, ngân hàng câu hỏi, bảng điều khiển hiệu quả khóa học, ví và yêu cầu rút tiền.

Đối với quản trị viên, vấn đề là kiểm soát chất lượng và an toàn vận hành. Nếu khóa học được công khai không qua kiểm duyệt, nền tảng có thể mất uy tín. Nếu thanh toán, doanh thu hoặc quyền truy cập không được kiểm soát, hệ thống có nguy cơ sai lệch dữ liệu. Hệ thống giải quyết bằng phân quyền quản trị, duyệt giảng viên, duyệt khóa học, quản lý người dùng, quản lý doanh thu, mã giảm giá và yêu cầu rút tiền.

Đối với doanh nghiệp, vấn đề là mua khóa học cho nhiều nhân viên không thể xử lý như từng học viên riêng lẻ. Doanh nghiệp cần mua số lượng lớn, cấp quyền học cho nhân viên, thu hồi hoặc theo dõi giấy phép, đồng thời xem báo cáo tiến độ. Hệ thống giải quyết bằng mô hình tổ chức, giấy phép học tập, hóa đơn, cổng doanh nghiệp và báo cáo nhân viên.

### 2.2. Các tác nhân

| Tác nhân | Vai trò nghiệp vụ | Mục tiêu sử dụng |
|---|---|---|
| Khách | Người chưa đăng nhập | Xem khóa học công khai, xem bài học xem trước, đăng ký tài khoản |
| Học viên | Người học cá nhân | Mua khóa học, học bài, làm kiểm tra, theo dõi tiến độ, nhận chứng chỉ |
| Giảng viên | Người tạo nội dung | Tạo khóa học, quản lý bài học, tạo câu hỏi, theo dõi học viên và doanh thu |
| Quản trị viên | Người vận hành hệ thống | Quản lý dữ liệu, duyệt khóa học, duyệt giảng viên, kiểm soát doanh thu |
| Quản trị doanh nghiệp | Đại diện tổ chức | Mua giấy phép, quản lý nhân viên, phân phối khóa học, xem báo cáo |
| Nhân viên | Người học thuộc doanh nghiệp | Học khóa học được doanh nghiệp cấp quyền |

### 2.3. Chức năng nghiệp vụ chính

#### Quản lý tài khoản và phân quyền

Mục đích của chức năng này là định danh người dùng và đảm bảo mỗi người dùng chỉ thực hiện được những thao tác phù hợp với vai trò của mình. Dữ liệu đầu vào gồm họ tên, email, mật khẩu, thông tin hồ sơ và vai trò. Hệ thống kiểm tra tính hợp lệ của email, mã hóa mật khẩu, xác nhận email và tạo hồ sơ mặc định. Kết quả đầu ra là tài khoản hợp lệ có thể sử dụng các chức năng tương ứng.

Chức năng này tồn tại vì hệ thống có nhiều nhóm người dùng với quyền hạn khác nhau. Nếu không có phân quyền rõ ràng, học viên có thể truy cập khu vực quản trị, giảng viên có thể sửa khóa học của người khác hoặc người chưa mua khóa học có thể xem nội dung trả phí.

#### Quản lý khóa học

Mục đích là cho phép giảng viên hoặc quản trị viên xây dựng sản phẩm đào tạo. Dữ liệu đầu vào gồm tiêu đề, mô tả, giá, danh mục, ảnh đại diện, kết quả học tập, chương học và bài học. Hệ thống lưu khóa học ở trạng thái bản nháp, cho phép bổ sung nội dung, sau đó gửi duyệt. Khi quản trị viên duyệt, khóa học chuyển sang trạng thái công khai. Kết quả đầu ra là khóa học có cấu trúc rõ ràng và có thể được học viên mua hoặc đăng ký.

Quy trình duyệt khóa học giúp bảo vệ chất lượng nền tảng. Đây là quyết định thiết kế quan trọng vì hệ thống có mô hình nhiều giảng viên cùng tạo nội dung, do đó cần lớp kiểm soát trước khi nội dung xuất hiện công khai.

#### Quản lý bài học và tài nguyên học tập

Mục đích là tổ chức nội dung học thành các bài có thứ tự. Dữ liệu đầu vào gồm tiêu đề bài học, mô tả, đường dẫn video, nội dung văn bản, tài liệu đính kèm, loại bài học và trạng thái xem trước miễn phí. Hệ thống lưu bài học trong từng chương, sắp xếp theo thứ tự và có thể tính thời lượng bài học từ video hoặc dữ liệu tải lên. Kết quả đầu ra là nội dung học tập có thể được hiển thị cho người học theo quyền truy cập.

#### Quản lý bài kiểm tra

Mục đích là đánh giá mức độ tiếp thu kiến thức của học viên. Dữ liệu đầu vào gồm câu hỏi, lựa chọn trả lời, đáp án đúng, độ khó, số lượng câu hỏi, thời gian làm bài và điểm đạt. Hệ thống có thể tạo bài kiểm tra gắn với bài học hoặc bài kiểm tra tổng của khóa học. Với bài kiểm tra ngẫu nhiên, hệ thống kiểm tra ngân hàng câu hỏi có đủ số lượng theo từng độ khó. Kết quả đầu ra là lượt làm bài, điểm số, trạng thái đạt hoặc chưa đạt.

Chức năng này hỗ trợ mục tiêu học tập vì khóa học trực tuyến không chỉ cung cấp nội dung mà còn cần cơ chế đánh giá kết quả.

#### Thanh toán và đăng ký khóa học

Mục đích là chuyển đổi nhu cầu học thành giao dịch hợp lệ. Dữ liệu đầu vào gồm khóa học, giỏ hàng, mã giảm giá, người mua, loại mua và số lượng. Hệ thống tạo phiên thanh toán thông qua Stripe, nhận kết quả qua webhook, sau đó tạo hoặc cập nhật đăng ký học. Kết quả đầu ra là học viên có quyền truy cập khóa học và hệ thống ghi nhận doanh thu.

Việc xử lý thanh toán bằng webhook là cần thiết vì kết quả thanh toán phải đến từ bên cung cấp thanh toán, không nên chỉ dựa vào thao tác quay lại trình duyệt của người dùng.

#### Theo dõi tiến độ và cấp chứng chỉ

Mục đích là giúp người học biết quá trình học của mình và tạo bằng chứng hoàn thành. Dữ liệu đầu vào gồm hành động hoàn thành bài học hoặc bài kiểm tra. Hệ thống tạo bản ghi tiến độ, ghi nhận hoạt động học, cập nhật mục tiêu học tập, cập nhật chuỗi ngày học và kiểm tra điều kiện cấp chứng chỉ. Kết quả đầu ra là tỷ lệ hoàn thành khóa học, lịch sử học tập và chứng chỉ nếu đủ điều kiện.

#### Gợi ý khóa học và kế hoạch học tập

Mục đích là cá nhân hóa trải nghiệm học tập. Dữ liệu đầu vào gồm lịch sử đăng ký, hành vi học tập, danh sách yêu thích, danh mục khóa học, điểm số và mức độ phổ biến. Hệ thống tính toán gợi ý bằng cách kết hợp nhiều nguồn điểm như nội dung tương đồng, hành vi người dùng tương tự và độ phổ biến. Với kế hoạch học tập, hệ thống dựa vào thời lượng bài học, hạn chót, thói quen học gần đây và thời gian học ưu tiên. Kết quả đầu ra là danh sách khóa học phù hợp và lịch học cá nhân.

#### Quản lý đào tạo doanh nghiệp

Mục đích là hỗ trợ tổ chức mua khóa học cho nhiều nhân viên. Dữ liệu đầu vào gồm tổ chức, khóa học, số lượng giấy phép, nhân viên và thời hạn. Hệ thống tạo hóa đơn, tạo giấy phép, cho phép gán giấy phép cho nhân viên và theo dõi trạng thái giấy phép. Kết quả đầu ra là danh sách nhân viên có quyền học và báo cáo tiến độ đào tạo.

## 3. Đặc Tả Yêu Cầu

### 3.1. Yêu cầu chức năng

Hệ thống phải cho phép người dùng đăng ký, đăng nhập, xác nhận email, khôi phục mật khẩu và chỉnh sửa hồ sơ cá nhân. Việc xác thực là nền tảng bắt buộc vì gần như mọi nghiệp vụ quan trọng như mua khóa học, học bài, làm bài kiểm tra hoặc quản lý nội dung đều gắn với danh tính người dùng.

Hệ thống phải hỗ trợ phân quyền theo vai trò. Học viên, giảng viên, quản trị viên, quản trị doanh nghiệp và nhân viên cần có phạm vi thao tác khác nhau. Đây là yêu cầu trọng yếu để đảm bảo an toàn dữ liệu và tính đúng đắn của quy trình nghiệp vụ.

Hệ thống phải cho phép quản lý danh mục khóa học theo cấu trúc cha con. Yêu cầu này giúp tổ chức khóa học theo lĩnh vực, hỗ trợ tìm kiếm, lọc và gợi ý khóa học.

Hệ thống phải cho phép giảng viên và quản trị viên tạo, cập nhật, sắp xếp và quản lý khóa học, chương học, bài học, tài nguyên học tập, câu hỏi và bài kiểm tra. Đây là nhóm chức năng cốt lõi vì khóa học là sản phẩm chính của nền tảng.

Hệ thống phải cho phép quản trị viên duyệt hoặc từ chối hồ sơ giảng viên và khóa học. Yêu cầu này nhằm bảo đảm chất lượng nội dung trước khi công khai.

Hệ thống phải cho phép khách và học viên tìm kiếm, lọc và xem thông tin khóa học công khai. Người dùng có thể lọc theo danh mục, mức giá và đánh giá để nhanh chóng tìm khóa học phù hợp.

Hệ thống phải cho phép học viên thêm khóa học vào giỏ hàng, thêm vào danh sách yêu thích, áp dụng mã giảm giá và thanh toán trực tuyến. Đây là nhóm yêu cầu phục vụ mục tiêu thương mại của nền tảng.

Hệ thống phải tự động kích hoạt quyền học sau khi thanh toán thành công. Quyền học được thể hiện bằng đăng ký khóa học, giấy phép doanh nghiệp hoặc gói đăng ký.

Hệ thống phải cho phép học viên học bài, ghi chú, bình luận, thảo luận, làm bài kiểm tra, xem kết quả và theo dõi tiến độ. Đây là nhóm yêu cầu phục vụ trải nghiệm học tập.

Hệ thống phải tự động ghi nhận hoạt động học, cập nhật mục tiêu học tập, chuỗi ngày học và cấp chứng chỉ khi hoàn thành điều kiện. Điều này giúp tăng động lực học và tạo giá trị sau khóa học.

Hệ thống phải cung cấp bảng điều khiển cho học viên, giảng viên, quản trị viên và doanh nghiệp. Mỗi bảng điều khiển phản ánh mục tiêu riêng của từng nhóm: học tập, giảng dạy, vận hành hoặc đào tạo tổ chức.

Hệ thống phải hỗ trợ doanh nghiệp mua nhiều giấy phép, gán giấy phép cho nhân viên, thu hồi giấy phép, quản lý hóa đơn và xem báo cáo tiến độ.

Hệ thống phải có cơ chế thông báo cho các sự kiện quan trọng như đăng ký học thành công, khóa học được duyệt hoặc bị từ chối, hoạt động liên quan đến người dùng.

### 3.2. Yêu cầu phi chức năng

Về bảo mật, hệ thống cần xác thực người dùng, xác nhận email, mã hóa mật khẩu, phân quyền theo vai trò và kiểm tra chữ ký webhook thanh toán. Yêu cầu này tồn tại vì hệ thống xử lý dữ liệu cá nhân, quyền truy cập nội dung trả phí và giao dịch tài chính.

Về hiệu năng, hệ thống cần phân trang danh sách khóa học, sử dụng chỉ mục cơ sở dữ liệu cho các trường thường truy vấn, nạp trước dữ liệu liên quan khi hiển thị danh sách và tính toán gợi ý khóa học bất đồng bộ. Nếu không có các biện pháp này, hệ thống dễ bị chậm khi số lượng khóa học, học viên và giao dịch tăng.

Về khả năng mở rộng, hệ thống được chia theo không gian tên nghiệp vụ như quản trị, giảng viên, học viên và doanh nghiệp. Cách tổ chức này giúp thêm chức năng mới mà không làm rối toàn bộ mã nguồn.

Về khả năng bảo trì, hệ thống áp dụng kiến trúc MVC, sử dụng lớp dịch vụ cho các nghiệp vụ phức tạp như mua giấy phép, lập kế hoạch học và gợi ý khóa học. Điều này giúp bộ điều khiển không chứa quá nhiều logic nghiệp vụ.

Về tính sẵn sàng triển khai, hệ thống có cấu hình Docker, cấu hình Render, đường kiểm tra sức khỏe `/health`, máy chủ Puma, biến môi trường cho các dịch vụ ngoài và cấu hình giám sát lỗi.

Về tính toàn vẹn dữ liệu, hệ thống sử dụng khóa ngoại, ràng buộc duy nhất và giao dịch cơ sở dữ liệu ở các nghiệp vụ quan trọng. Ví dụ, một học viên không được đăng ký trùng một khóa học, một khóa học không được xuất hiện trùng trong danh sách yêu thích của cùng một người dùng.

## 4. Use Case

### UC01 - Đăng ký tài khoản

Mục tiêu của ca sử dụng là cho phép khách trở thành người dùng hợp lệ trong hệ thống. Tác nhân là khách chưa đăng nhập. Điều kiện tiên quyết là khách có email hợp lệ và chưa tồn tại trong hệ thống.

Luồng chính bắt đầu khi khách mở màn hình đăng ký, nhập họ tên, email và mật khẩu. Hệ thống kiểm tra định dạng email, kiểm tra email chưa bị trùng, kiểm tra mật khẩu và tạo tài khoản. Sau đó hệ thống gửi email xác nhận và tạo hồ sơ mặc định cho người dùng. Khi người dùng xác nhận email, tài khoản có thể đăng nhập.

Luồng thay thế xảy ra khi email đã tồn tại, mật khẩu không hợp lệ hoặc người dùng chưa xác nhận email. Khi đó hệ thống hiển thị lỗi và không cho phép hoàn tất đăng ký hoặc đăng nhập đầy đủ. Kết quả của ca sử dụng là người dùng có tài khoản vai trò học viên và có thể sử dụng các chức năng cá nhân.

### UC02 - Tìm kiếm và xem khóa học

Mục tiêu là giúp người dùng tìm khóa học phù hợp. Tác nhân gồm khách và học viên. Điều kiện tiên quyết là khóa học phải ở trạng thái công khai.

Luồng chính bắt đầu khi người dùng truy cập danh sách khóa học. Người dùng nhập từ khóa hoặc chọn bộ lọc như danh mục, miễn phí, trả phí hoặc đánh giá tối thiểu. Hệ thống truy vấn các khóa học công khai, áp dụng bộ lọc, phân trang và hiển thị kết quả. Người dùng chọn một khóa học để xem chi tiết, bao gồm mô tả, giảng viên, chương học, bài học, bài kiểm tra và đánh giá.

Luồng thay thế xảy ra khi không có khóa học phù hợp hoặc khóa học đã bị ẩn. Hệ thống hiển thị danh sách rỗng hoặc chuyển hướng về trang danh sách kèm thông báo. Kết quả là người dùng hiểu được nội dung khóa học trước khi quyết định mua hoặc học.

### UC03 - Mua khóa học

Mục tiêu là cho phép học viên thanh toán và được cấp quyền học. Tác nhân là học viên đã đăng nhập. Điều kiện tiên quyết là khóa học tồn tại, học viên chưa có quyền học hoặc muốn mua thêm qua giỏ hàng.

Luồng chính bắt đầu khi học viên chọn mua trực tiếp hoặc thanh toán giỏ hàng. Hệ thống tính giá, áp dụng mã giảm giá nếu có, kiểm tra số tiền tối thiểu theo yêu cầu thanh toán và tạo phiên thanh toán Stripe. Học viên hoàn tất thanh toán trên Stripe. Stripe gửi webhook về hệ thống. Hệ thống xác thực webhook, tạo hoặc cập nhật bản ghi đăng ký khóa học ở trạng thái hoạt động và tạo thông báo cho học viên, đồng thời có thể cập nhật gợi ý khóa học.

Luồng thay thế gồm trường hợp giỏ hàng rỗng, mã giảm giá không hợp lệ, số tiền dưới mức tối thiểu hoặc thanh toán thất bại. Khi đó hệ thống không cấp quyền học và thông báo lỗi tương ứng. Kết quả thành công là học viên có quyền truy cập nội dung khóa học.

### UC04 - Học bài và cập nhật tiến độ

Mục tiêu là ghi nhận quá trình học của học viên. Tác nhân là học viên hoặc nhân viên doanh nghiệp. Điều kiện tiên quyết là người dùng đã có quyền truy cập khóa học, hoặc bài học được đánh dấu xem trước miễn phí.

Luồng chính bắt đầu khi người dùng mở bài học. Hệ thống kiểm tra quyền truy cập thông qua đăng ký khóa học, giấy phép doanh nghiệp, quyền sở hữu khóa học hoặc gói đăng ký. Người dùng xem video, đọc nội dung, tải tài liệu, ghi chú hoặc bình luận. Khi người dùng hoàn thành bài học, hệ thống tạo hoặc cập nhật tiến độ, ghi nhận hoạt động học, cập nhật chuỗi ngày học và mục tiêu học tập.

Luồng thay thế xảy ra khi người dùng chưa mua khóa học hoặc không có giấy phép hợp lệ. Hệ thống chỉ cho phép xem bài học miễn phí hoặc chặn truy cập nội dung trả phí. Kết quả là tiến độ học tập được lưu trữ và có thể dùng cho chứng chỉ, dashboard và gợi ý học tập.

### UC05 - Làm bài kiểm tra

Mục tiêu là đánh giá kiến thức của học viên. Tác nhân là học viên có quyền học khóa học. Điều kiện tiên quyết là bài kiểm tra tồn tại và có đủ câu hỏi hợp lệ.

Luồng chính bắt đầu khi học viên bắt đầu bài kiểm tra. Hệ thống tạo lượt làm bài, hiển thị câu hỏi theo cấu hình, nhận câu trả lời và tính điểm. Khi học viên nộp bài, hệ thống lưu câu trả lời, điểm số, trạng thái đạt hoặc chưa đạt và cập nhật tiến độ nếu đạt điều kiện.

Luồng thay thế gồm hết thời gian, trả lời thiếu câu hoặc bài kiểm tra không đủ ngân hàng câu hỏi. Hệ thống cần xử lý bằng cách chấm theo dữ liệu đã có hoặc thông báo lỗi cấu hình. Kết quả là học viên nhận được điểm và có thể xem lại kết quả.

### UC06 - Giảng viên tạo và gửi duyệt khóa học

Mục tiêu là chuẩn hóa quy trình đưa khóa học lên nền tảng. Tác nhân là giảng viên đã được chấp nhận. Điều kiện tiên quyết là giảng viên đã đăng nhập và có quyền tạo khóa học.

Luồng chính bắt đầu khi giảng viên tạo khóa học ở trạng thái bản nháp, nhập thông tin khóa học, thêm chương, thêm bài học, tạo câu hỏi và bài kiểm tra. Khi nội dung đã sẵn sàng, giảng viên gửi khóa học để duyệt. Hệ thống chuyển trạng thái khóa học sang chờ duyệt.

Luồng thay thế xảy ra khi khóa học thiếu thông tin bắt buộc hoặc giảng viên không có quyền sửa khóa học. Hệ thống từ chối thao tác và hiển thị lỗi. Kết quả là khóa học được đưa vào hàng đợi kiểm duyệt.

### UC07 - Quản trị viên duyệt khóa học

Mục tiêu là kiểm soát chất lượng nội dung. Tác nhân là quản trị viên. Điều kiện tiên quyết là có khóa học đang chờ duyệt.

Luồng chính bắt đầu khi quản trị viên mở danh sách khóa học cần duyệt. Quản trị viên xem nội dung, đánh giá tính phù hợp và chọn phê duyệt hoặc từ chối. Nếu phê duyệt, hệ thống chuyển khóa học sang công khai. Nếu từ chối, hệ thống chuyển sang trạng thái bị từ chối và có thể lưu lý do. Hệ thống tạo thông báo cho giảng viên.

Luồng thay thế xảy ra khi khóa học đã bị xử lý bởi quản trị viên khác hoặc không tồn tại. Hệ thống thông báo trạng thái hiện tại. Kết quả là khóa học chỉ được công khai khi vượt qua bước kiểm duyệt.

### UC08 - Doanh nghiệp mua và gán giấy phép

Mục tiêu là cho phép tổ chức đào tạo nhiều nhân viên. Tác nhân là quản trị doanh nghiệp. Điều kiện tiên quyết là người dùng thuộc một tổ chức hợp lệ.

Luồng chính bắt đầu khi quản trị doanh nghiệp chọn khóa học trong cổng doanh nghiệp, nhập số lượng giấy phép và thanh toán. Sau khi Stripe xác nhận thanh toán, hệ thống tạo hóa đơn và các giấy phép có mã riêng. Quản trị doanh nghiệp gán giấy phép cho nhân viên. Nhân viên sau đó có quyền học khóa học tương ứng.

Luồng thay thế gồm thanh toán thất bại, tổ chức không tồn tại, không còn giấy phép trống hoặc giấy phép hết hạn. Hệ thống không cấp quyền học và hiển thị thông báo phù hợp. Kết quả là doanh nghiệp có thể quản lý quyền học tập tập trung.

## 5. Phân Tích Dữ Liệu

### 5.1. Mô hình dữ liệu

Cơ sở dữ liệu được thiết kế xoay quanh các thực thể nghiệp vụ chính: người dùng, khóa học, nội dung học tập, đăng ký học, thanh toán, tiến độ, bài kiểm tra, doanh nghiệp và gợi ý học tập.

Bảng `users` lưu thông tin tài khoản, email, mật khẩu đã mã hóa, vai trò và liên kết tổ chức. Đây là bảng trung tâm vì hầu hết dữ liệu nghiệp vụ đều gắn với người dùng. Bảng `profiles` lưu thông tin hồ sơ cá nhân, còn `instructor_profiles` lưu hồ sơ đăng ký giảng viên, trạng thái duyệt và thông tin ngân hàng.

Bảng `organizations` đại diện cho doanh nghiệp. Bảng này liên kết với người dùng thuộc doanh nghiệp và giấy phép học tập. Việc tách tổ chức thành bảng riêng giúp hệ thống hỗ trợ mô hình doanh nghiệp thay vì chỉ phục vụ học viên cá nhân.

Bảng `categories` lưu danh mục khóa học và có quan hệ cha con. Bảng `courses` lưu thông tin khóa học như tiêu đề, mô tả, giá, trạng thái, người tạo và danh mục. Bảng `course_modules` chia khóa học thành các chương, còn `lessons` lưu bài học cụ thể.

Bảng `enrollments` lưu quan hệ học viên đăng ký khóa học. Đây là dữ liệu thể hiện quyền học sau khi mua hoặc đăng ký thành công. Bảng `progress_trackings` lưu tiến độ từng bài học hoặc bài kiểm tra, từ đó tính phần trăm hoàn thành khóa học.

Bảng `quizzes`, `questions`, `question_options`, `quiz_questions`, `quiz_attempts` và `quiz_answers` tạo thành mô hình kiểm tra. Cách tách câu hỏi khỏi bài kiểm tra giúp xây dựng ngân hàng câu hỏi và tái sử dụng câu hỏi cho nhiều bài kiểm tra.

Bảng `carts`, `cart_items`, `coupons`, `subscriptions`, `wallets`, `wallet_transactions` và `payout_requests` phục vụ nghiệp vụ thương mại. Trong đó ví và giao dịch ví phản ánh doanh thu của giảng viên và nền tảng.

Bảng `licenses` và `invoices` phục vụ mô hình doanh nghiệp. Giấy phép cho phép doanh nghiệp mua nhiều quyền học và phân phối cho nhân viên. Hóa đơn lưu thông tin giao dịch doanh nghiệp.

Bảng `notifications`, `wishlists`, `reviews`, `comments`, `discussion_posts`, `discussion_replies`, `discussion_messages`, `message_reactions` hỗ trợ tương tác người dùng, phản hồi và cộng đồng học tập.

Bảng `learning_activities`, `learning_goals`, `learning_streaks`, `study_plans`, `study_plan_items`, `study_plan_adjustments`, `user_recommendations` và `course_similarities` phục vụ cá nhân hóa học tập và phân tích hành vi.

### 5.2. Quan hệ dữ liệu

Quan hệ một - một xuất hiện giữa người dùng và hồ sơ cá nhân, người dùng và ví, người dùng và chuỗi học tập. Các quan hệ này phản ánh những dữ liệu mở rộng trực tiếp của tài khoản.

Quan hệ một - nhiều xuất hiện rất phổ biến. Một danh mục có nhiều khóa học, một khóa học có nhiều chương, một chương có nhiều bài học, một khóa học có nhiều đăng ký học, một người dùng có nhiều tiến độ học, một doanh nghiệp có nhiều giấy phép. Đây là kiểu quan hệ phù hợp với cấu trúc phân cấp của hệ thống học trực tuyến.

Quan hệ nhiều - nhiều được triển khai thông qua bảng trung gian. Người dùng và khóa học có quan hệ nhiều - nhiều thông qua `enrollments`, vì một học viên có thể học nhiều khóa và một khóa có nhiều học viên. Người dùng và khóa học cũng có quan hệ nhiều - nhiều thông qua `wishlists`. Bài kiểm tra và câu hỏi có quan hệ nhiều - nhiều thông qua `quiz_questions`.

### 5.3. Luồng dữ liệu

Khi người dùng đăng ký, dữ liệu được tạo trong `users`, đồng thời hệ thống tạo `profiles` và `wallets`. Khi người dùng trở thành giảng viên, dữ liệu bổ sung được lưu ở `instructor_profiles`.

Khi giảng viên tạo khóa học, dữ liệu được lưu dần vào `courses`, `course_modules`, `lessons`, `questions` và `quizzes`. Trạng thái của khóa học quyết định khóa học có được hiển thị cho học viên hay không.

Khi học viên mua khóa học, dữ liệu giao dịch đi qua Stripe. Sau khi webhook xác nhận, hệ thống cập nhật `enrollments`, tạo `notifications`, có thể ghi nhận `wallet_transactions` và kích hoạt tính toán gợi ý.

Khi học viên học bài, hệ thống đọc dữ liệu khóa học và bài học, sau đó cập nhật `progress_trackings`, `learning_activities`, `learning_streaks` và `learning_goals`. Nếu điều kiện hoàn thành được đáp ứng, hệ thống tạo `certificates`.

Khi doanh nghiệp mua giấy phép, hệ thống tạo `invoices` và nhiều bản ghi `licenses`. Khi giấy phép được gán cho nhân viên, trường người dùng trong giấy phép được cập nhật, từ đó nhân viên có quyền truy cập khóa học.

## 6. Thiết Kế Hệ Thống

### 6.1. Kiến trúc tổng thể

Hệ thống sử dụng kiến trúc đơn khối (Monolithic Architecture) trên nền Ruby on Rails. Bên trong ứng dụng, kiến trúc MVC (Model View Controller) được áp dụng rõ ràng. Mô hình chịu trách nhiệm dữ liệu và quy tắc nghiệp vụ cơ bản, bộ điều khiển xử lý yêu cầu người dùng, giao diện hiển thị dữ liệu, còn các lớp dịch vụ xử lý nghiệp vụ phức tạp.

Việc lựa chọn kiến trúc đơn khối là phù hợp với đồ án và hệ thống có quy mô vừa. Nó giúp phát triển nhanh, dễ triển khai, dễ kiểm thử tích hợp và không phát sinh độ phức tạp của giao tiếp giữa nhiều dịch vụ nhỏ. Đồng thời, việc chia không gian tên theo nghiệp vụ vẫn giúp mã nguồn có khả năng mở rộng.

### 6.2. Các thành phần

Thành phần giao diện sử dụng ERB, Slim, SCSS, Bootstrap, Hotwire Turbo và Stimulus. Cách tiếp cận này phù hợp với Rails vì phần lớn giao diện được kết xuất từ máy chủ, trong khi Turbo và Stimulus bổ sung tương tác động mà không cần xây dựng ứng dụng giao diện tách rời hoàn toàn.

Thành phần xử lý nghiệp vụ là Rails backend, gồm bộ điều khiển, mô hình, dịch vụ và công việc nền. Các nghiệp vụ như thanh toán, lập kế hoạch học, mua giấy phép và gợi ý khóa học được đưa vào lớp dịch vụ để giảm tải cho bộ điều khiển.

Thành phần dữ liệu là PostgreSQL. Đây là lựa chọn phù hợp vì hệ thống có nhiều quan hệ dữ liệu, cần khóa ngoại, chỉ mục, giao dịch và truy vấn tổng hợp.

Thành phần lưu trữ tệp dùng Active Storage kết hợp Cloudinary. Hệ thống cần lưu ảnh, video và tài liệu học tập, do đó lưu trữ ngoài giúp giảm tải máy chủ ứng dụng.

Thành phần xác thực dùng Devise, phân quyền dùng CanCanCan. Đây là quyết định hợp lý vì dự án có nhiều vai trò, nhiều vùng chức năng và nhiều quy tắc truy cập.

Thành phần thanh toán dùng Stripe. Stripe giúp tách rủi ro xử lý thẻ khỏi ứng dụng và cung cấp webhook để đồng bộ trạng thái giao dịch đáng tin cậy.

Thành phần công việc nền dùng Active Job và Redis. Các tác vụ như tính gợi ý, nhắc lịch học hoặc xử lý giấy phép hết hạn không nên chạy trực tiếp trong yêu cầu giao diện vì có thể làm chậm trải nghiệm người dùng.

### 6.3. Luồng xử lý chính

Luồng đăng ký học bắt đầu từ việc người dùng chọn khóa học. Nếu khóa học miễn phí hoặc được gói đăng ký cho phép, hệ thống có thể cấp quyền truy cập trực tiếp. Nếu là khóa học trả phí, người dùng đi qua quy trình thanh toán. Sau khi thanh toán thành công, webhook cập nhật đăng ký học và từ đó người dùng được quyền truy cập nội dung.

Luồng tạo khóa học bắt đầu từ giảng viên tạo bản nháp. Giảng viên bổ sung chương, bài học, câu hỏi và bài kiểm tra. Khi hoàn tất, giảng viên gửi duyệt. Quản trị viên kiểm tra và thay đổi trạng thái khóa học. Chỉ khóa học đã công khai mới xuất hiện ở trang danh sách cho khách và học viên.

Luồng học tập bắt đầu khi người dùng mở bài học. Hệ thống kiểm tra quyền truy cập. Nếu hợp lệ, hệ thống hiển thị nội dung. Khi người dùng hoàn thành, hệ thống ghi tiến độ, hoạt động học và cập nhật dashboard cá nhân.

Luồng doanh nghiệp bắt đầu từ việc quản trị doanh nghiệp mua giấy phép. Sau khi thanh toán thành công, hệ thống tạo hóa đơn và giấy phép. Quản trị doanh nghiệp gán giấy phép cho nhân viên. Nhân viên sử dụng giấy phép để truy cập khóa học.

## 7. Thiết Kế Chức Năng

### 7.1. Module tài khoản và phân quyền

Module này đảm bảo mỗi yêu cầu đến hệ thống đều được xử lý theo danh tính và quyền hạn phù hợp. Thành phần liên quan gồm `User`, `Profile`, `InstructorProfile`, Devise và `Ability`. Luồng hoạt động bắt đầu từ đăng ký hoặc đăng nhập, sau đó hệ thống xác định vai trò và kiểm tra quyền trước khi cho phép thao tác.

Quy tắc nghiệp vụ quan trọng là email không được trùng, mật khẩu phải đủ mạnh, người dùng chưa xác thực email bị hạn chế, và mỗi vai trò chỉ được truy cập vùng chức năng tương ứng. Quy tắc này tồn tại để bảo vệ dữ liệu và tránh lạm quyền.

### 7.2. Module khóa học

Module khóa học là trung tâm của hệ thống. Thành phần liên quan gồm `Course`, `Category`, `CourseModule`, `Lesson`, `CourseLearningOutcome`, ảnh khóa học và tài nguyên bài học. Luồng hoạt động gồm tạo khóa học, thêm nội dung, sắp xếp thứ tự, gửi duyệt và công khai.

Quy tắc nghiệp vụ là khóa học phải có tiêu đề, giá không âm, khóa học của giảng viên phải qua trạng thái duyệt trước khi công khai. Việc có trạng thái khóa học giúp nền tảng kiểm soát vòng đời nội dung.

### 7.3. Module học tập

Module học tập quản lý việc truy cập bài học, ghi chú, bình luận, tiến độ và chứng chỉ. Thành phần liên quan gồm `Lesson`, `Enrollment`, `ProgressTracking`, `Note`, `Comment`, `Certificate`, `LearningActivity`, `LearningGoal` và `LearningStreak`.

Luồng hoạt động bắt đầu khi người dùng mở bài học. Hệ thống kiểm tra quyền truy cập, hiển thị nội dung và nhận hành động hoàn thành. Sau đó hệ thống cập nhật tiến độ và các dữ liệu phân tích học tập. Quy tắc nghiệp vụ là chỉ người có quyền mới được học nội dung trả phí, còn bài học xem trước có thể mở cho khách.

### 7.4. Module bài kiểm tra

Module này phục vụ đánh giá năng lực. Thành phần liên quan gồm `Quiz`, `Question`, `QuestionOption`, `QuizQuestion`, `QuizAttempt` và `QuizAnswer`. Luồng hoạt động gồm giảng viên tạo ngân hàng câu hỏi, tạo bài kiểm tra, học viên làm bài, hệ thống chấm điểm và lưu kết quả.

Quy tắc nghiệp vụ là số lượng câu hỏi theo độ khó phải khớp tổng số câu hỏi, ngân hàng câu hỏi phải đủ để tạo đề ngẫu nhiên, điểm đạt được xác định theo cấu hình bài kiểm tra. Các quy tắc này giúp đảm bảo bài kiểm tra có tính hợp lệ và công bằng.

### 7.5. Module thương mại và thanh toán

Module này biến khóa học thành sản phẩm có thể giao dịch. Thành phần liên quan gồm `Cart`, `CartItem`, `Coupon`, `Checkout`, `Webhook`, `Enrollment`, `Subscription`, `Wallet`, `WalletTransaction` và `PayoutRequest`.

Luồng hoạt động gồm thêm khóa học vào giỏ, áp dụng mã giảm giá, tạo phiên thanh toán, nhận webhook, kích hoạt đăng ký học và ghi nhận doanh thu. Quy tắc nghiệp vụ là thanh toán thành công mới cấp quyền học, mã giảm giá phải còn hiệu lực, doanh thu được chia cho giảng viên và nền tảng theo tỷ lệ 70/30.

### 7.6. Module quản trị

Module quản trị cho phép vận hành hệ thống ở cấp cao. Thành phần liên quan gồm các bộ điều khiển trong vùng `admin`, các mô hình người dùng, khóa học, danh mục, bình luận, đánh giá, coupon, payout và revenue.

Luồng hoạt động gồm quản lý dữ liệu nền tảng, duyệt giảng viên, duyệt khóa học, theo dõi doanh thu và xử lý rút tiền. Quy tắc nghiệp vụ là chỉ quản trị viên mới được truy cập toàn quyền, vì các thao tác này ảnh hưởng đến toàn bộ hệ thống.

### 7.7. Module giảng viên

Module giảng viên cung cấp công cụ sản xuất nội dung và theo dõi hiệu quả. Thành phần liên quan gồm vùng `instructor`, khóa học do giảng viên tạo, doanh thu, học viên, bài kiểm tra, câu hỏi và yêu cầu rút tiền.

Luồng hoạt động gồm quản lý khóa học, theo dõi học viên, xem doanh thu, tạo mã giảm giá và yêu cầu rút tiền. Quy tắc nghiệp vụ là giảng viên chỉ được quản lý tài nguyên do mình tạo, không được can thiệp khóa học của người khác.

### 7.8. Module doanh nghiệp

Module doanh nghiệp hỗ trợ đào tạo theo tổ chức. Thành phần liên quan gồm `Organization`, `License`, `Invoice`, nhân viên và vùng `business`. Luồng hoạt động gồm đăng ký doanh nghiệp, mua giấy phép, quản lý nhân viên, gán giấy phép và xem báo cáo.

Quy tắc nghiệp vụ là quản trị doanh nghiệp chỉ được quản lý dữ liệu thuộc tổ chức của mình. Giấy phép phải ở trạng thái còn hiệu lực và được gán cho nhân viên thì nhân viên mới có quyền học.

### 7.9. Module gợi ý và kế hoạch học tập

Module này nâng cao trải nghiệm cá nhân hóa. Thành phần liên quan gồm `UserRecommendation`, `CourseSimilarity`, `LearningActivity`, `StudyPlan`, `StudyPlanItem` và các dịch vụ gợi ý. Luồng hoạt động gồm ghi nhận hành vi học tập, tính điểm gợi ý, lưu kết quả và hiển thị cho học viên.

Quy tắc nghiệp vụ là hệ thống nên ưu tiên khóa học phù hợp với hành vi và sở thích của người học, đồng thời tránh gợi ý lại khóa học mà người dùng đã học. Điều này giúp tăng khả năng tiếp tục học và tăng giá trị kinh doanh của nền tảng.

## 8. Quy Tắc Nghiệp Vụ

Email người dùng không được trùng vì email là định danh đăng nhập chính. Nếu cho phép trùng email, hệ thống không thể xác định chính xác tài khoản khi đăng nhập hoặc gửi email xác nhận.

Mật khẩu phải đáp ứng yêu cầu độ mạnh vì hệ thống xử lý dữ liệu cá nhân, lịch sử học tập và giao dịch thanh toán. Quy tắc này giảm nguy cơ tài khoản bị chiếm đoạt.

Người dùng phải xác nhận email để đảm bảo email thuộc về người đăng ký. Điều này giúp giảm tài khoản giả và hỗ trợ các chức năng gửi thông báo, đặt lại mật khẩu.

Mỗi người dùng có một vai trò chính như học viên, giảng viên, quản trị viên, quản trị doanh nghiệp hoặc nhân viên. Vai trò quyết định khu vực truy cập và thao tác được phép thực hiện.

Khách chỉ được xem nội dung công khai và bài học xem trước. Quy tắc này giúp quảng bá khóa học nhưng vẫn bảo vệ nội dung trả phí.

Học viên chỉ được truy cập khóa học khi đã đăng ký hoạt động, có giấy phép hợp lệ, là chủ sở hữu khóa học hoặc có gói đăng ký phù hợp. Đây là quy tắc cốt lõi để bảo vệ doanh thu của nền tảng.

Giảng viên chỉ được quản lý khóa học, bài học, câu hỏi và bài kiểm tra do mình tạo. Quy tắc này bảo vệ quyền sở hữu nội dung của từng giảng viên.

Khóa học có các trạng thái bản nháp, chờ duyệt, công khai và bị từ chối. Chỉ khóa học công khai mới hiển thị cho người dùng ngoài. Quy tắc này giúp kiểm soát chất lượng nội dung.

Giá khóa học không được âm vì giá là dữ liệu tài chính. Giá âm có thể gây sai lệch thanh toán và doanh thu.

Một học viên không được đăng ký trùng cùng một khóa học. Quy tắc này tránh lặp dữ liệu và sai lệch thống kê số học viên.

Một khóa học không được xuất hiện trùng trong danh sách yêu thích của cùng một người dùng. Quy tắc này giữ dữ liệu gọn và phản ánh đúng ý định người dùng.

Mã giảm giá phải có thời gian bắt đầu, thời gian kết thúc, giá trị giảm hợp lệ và giới hạn sử dụng nếu có. Quy tắc này giúp kiểm soát chiến dịch khuyến mại và tránh lạm dụng.

Mã giảm giá theo khóa học cụ thể phải liên kết với một khóa học. Nếu không, hệ thống không biết áp dụng mã cho sản phẩm nào.

Thanh toán thành công mới tạo quyền học. Quy tắc này bảo đảm quyền truy cập nội dung trả phí chỉ phát sinh khi giao dịch đã được xác nhận.

Webhook thanh toán phải được xác thực chữ ký. Điều này ngăn yêu cầu giả mạo từ bên ngoài tạo quyền học hoặc thay đổi trạng thái giao dịch.

Doanh thu được chia theo tỷ lệ 70% cho giảng viên và 30% cho nền tảng. Quy tắc này phản ánh mô hình kinh doanh của hệ thống.

Giấy phép doanh nghiệp có trạng thái khả dụng, đã gán hoặc hết hạn. Nhân viên chỉ được học khi giấy phép đã gán và chưa hết hạn. Quy tắc này giúp doanh nghiệp kiểm soát ngân sách đào tạo.

Bài kiểm tra ngẫu nhiên phải có đủ số lượng câu hỏi theo từng độ khó. Quy tắc này đảm bảo đề thi tạo ra hợp lệ và không thiên lệch.

Chứng chỉ chỉ nên được cấp khi người học hoàn thành khóa học theo điều kiện hệ thống. Quy tắc này bảo vệ giá trị của chứng chỉ.

Đánh giá khóa học nên gắn với người học đã tham gia khóa học và trong mã nguồn có dấu hiệu yêu cầu tiến độ tối thiểu để đánh giá. Quy tắc này giúp đánh giá đáng tin cậy hơn, tránh nhận xét từ người chưa học.

## 9. Công Nghệ Sử Dụng

Hệ thống sử dụng Ruby và Ruby on Rails làm nền tảng phát triển. Rails phù hợp với dự án vì hỗ trợ nhanh kiến trúc MVC, định tuyến, cơ sở dữ liệu, gửi email, công việc nền và bảo mật cơ bản.

PostgreSQL được sử dụng làm hệ quản trị cơ sở dữ liệu. Đây là lựa chọn hợp lý vì hệ thống có nhiều quan hệ dữ liệu, cần khóa ngoại, chỉ mục, giao dịch và truy vấn tổng hợp.

Devise được dùng cho xác thực, CanCanCan dùng cho phân quyền. Hai thư viện này giúp giảm rủi ro khi tự xây dựng cơ chế đăng nhập và kiểm soát quyền.

Stripe được dùng cho thanh toán trực tuyến. Lựa chọn này giúp hệ thống không trực tiếp xử lý thông tin thẻ, đồng thời có webhook để xác nhận giao dịch.

Active Storage và Cloudinary được dùng cho lưu trữ tệp, video và tài liệu. Điều này phù hợp với hệ thống E-Learning vì nội dung học tập thường có dung lượng lớn.

Hotwire Turbo, Stimulus, ERB, Slim, SCSS và Bootstrap được dùng cho giao diện. Cách tiếp cận này phù hợp với ứng dụng Rails đơn khối, giúp xây dựng giao diện động vừa đủ mà không cần tách frontend thành ứng dụng riêng.

Ransack, Pagy, Chartkick và Groupdate hỗ trợ tìm kiếm, phân trang và biểu đồ. Các thư viện này phục vụ trực tiếp nhu cầu tra cứu khóa học và hiển thị dashboard.

Redis và Active Job hỗ trợ xử lý nền. Các tác vụ như tính gợi ý hoặc xử lý nhắc nhở không nên chạy đồng bộ trong yêu cầu người dùng.

Sentry, Docker, Render và Puma hỗ trợ triển khai, vận hành và giám sát. Đây là nhóm công nghệ giúp hệ thống có khả năng chạy ở môi trường sản xuất.

## 10. Kiểm Thử Hệ Thống

### 10.1. Kiểm thử chức năng

Kiểm thử chức năng cần tập trung vào các luồng nghiệp vụ chính. Đầu tiên là đăng ký, đăng nhập, xác nhận email và phân quyền. Tiếp theo là tìm kiếm khóa học, mua khóa học, học bài, làm bài kiểm tra, cập nhật tiến độ và cấp chứng chỉ. Với giảng viên, cần kiểm thử tạo khóa học, gửi duyệt, quản lý bài học và xem doanh thu. Với quản trị viên, cần kiểm thử duyệt khóa học, quản lý người dùng và xử lý yêu cầu rút tiền. Với doanh nghiệp, cần kiểm thử mua giấy phép, gán giấy phép và xem báo cáo.

### 10.2. Kiểm thử tích hợp

Kiểm thử tích hợp đặc biệt quan trọng với thanh toán Stripe, webhook, Cloudinary, email và công việc nền. Ví dụ, sau khi Stripe gửi webhook thanh toán thành công, hệ thống phải tạo đăng ký học và người dùng phải truy cập được khóa học. Nếu một trong các bước bị lỗi, trải nghiệm người dùng và dữ liệu doanh thu sẽ sai lệch.

### 10.3. Kiểm thử giao diện

Kiểm thử giao diện cần đảm bảo các màn hình quan trọng hiển thị đúng theo vai trò. Học viên không được nhìn thấy chức năng quản trị. Giảng viên chỉ nhìn thấy khóa học của mình. Quản trị doanh nghiệp chỉ nhìn thấy nhân viên và giấy phép thuộc tổ chức của mình. Giao diện danh sách khóa học, chi tiết khóa học, trang học bài, bảng điều khiển và trang thanh toán cần được kiểm thử ở các kích thước màn hình khác nhau.

### 10.4. Các trường hợp kiểm thử tiêu biểu

| Mã kiểm thử | Tình huống | Dữ liệu đầu vào | Kết quả mong đợi |
|---|---|---|---|
| TC01 | Đăng ký email mới | Email chưa tồn tại, mật khẩu hợp lệ | Tạo tài khoản và gửi email xác nhận |
| TC02 | Đăng ký email trùng | Email đã tồn tại | Hiển thị lỗi, không tạo tài khoản |
| TC03 | Học viên mua khóa học | Khóa học trả phí, thanh toán thành công | Tạo đăng ký học trạng thái hoạt động |
| TC04 | Truy cập khóa học chưa mua | Học viên không có đăng ký | Chặn nội dung trả phí |
| TC05 | Bài học xem trước | Khách mở bài học miễn phí | Cho phép xem nội dung |
| TC06 | Giảng viên sửa khóa học người khác | Tài khoản giảng viên không phải chủ sở hữu | Từ chối quyền truy cập |
| TC07 | Admin duyệt khóa học | Khóa học chờ duyệt | Khóa học chuyển sang công khai |
| TC08 | Áp dụng mã giảm giá hết hạn | Coupon đã hết hạn | Không áp dụng giảm giá |
| TC09 | Làm bài kiểm tra đạt điểm | Câu trả lời đúng đủ điểm đạt | Lưu kết quả đạt và cập nhật tiến độ |
| TC10 | Doanh nghiệp gán giấy phép | License khả dụng, nhân viên hợp lệ | License chuyển sang đã gán, nhân viên có quyền học |
| TC11 | Giấy phép hết hạn | License quá hạn | Nhân viên không còn quyền học qua license |
| TC12 | Cấp chứng chỉ | Hoàn thành đủ điều kiện khóa học | Tạo chứng chỉ duy nhất cho học viên |

### 10.5. Nhận xét về hiện trạng kiểm thử

Trong mã nguồn hiện có, hệ thống đã có một số kiểm thử cho thông báo, gói đăng ký và danh sách yêu thích. Tuy nhiên, độ bao phủ kiểm thử chưa tương xứng với độ rộng nghiệp vụ. Các phần nên ưu tiên bổ sung kiểm thử gồm webhook thanh toán, phân quyền, chia doanh thu, bài kiểm tra, tiến độ học, cấp chứng chỉ, giấy phép doanh nghiệp và gợi ý khóa học.

## 11. Đánh Giá Hệ Thống

### 11.1. Ưu điểm

Hệ thống có phạm vi nghiệp vụ phong phú và phản ánh khá đầy đủ một nền tảng E-Learning hiện đại. Việc hỗ trợ nhiều vai trò giúp hệ thống không chỉ phục vụ học viên cá nhân mà còn phục vụ giảng viên, quản trị viên và doanh nghiệp.

Thiết kế dữ liệu tương đối đầy đủ, có nhiều bảng thể hiện đúng thực thể nghiệp vụ như khóa học, bài học, bài kiểm tra, đăng ký học, tiến độ, chứng chỉ, giấy phép, hóa đơn, ví và giao dịch ví. Điều này cho thấy dự án không chỉ là giao diện CRUD đơn giản mà có tư duy mô hình hóa nghiệp vụ.

Kiến trúc Rails MVC kết hợp lớp dịch vụ giúp dự án dễ hiểu và phù hợp với quy trình phát triển phần mềm trong đồ án. Các nghiệp vụ phức tạp như lập kế hoạch học, mua giấy phép và gợi ý khóa học được tách khỏi bộ điều khiển, giúp mã nguồn có khả năng bảo trì tốt hơn.

Hệ thống có tích hợp các dịch vụ thực tế như Stripe, Cloudinary, email, Sentry và Render. Đây là điểm mạnh vì báo cáo có thể trình bày cả khía cạnh triển khai và vận hành, không chỉ dừng ở phát triển cục bộ.

Các chức năng cá nhân hóa như mục tiêu học tập, chuỗi ngày học, kế hoạch học và gợi ý khóa học giúp hệ thống có giá trị cao hơn so với một nền tảng đăng bán khóa học thông thường.

### 11.2. Hạn chế

Tài liệu đặc tả nghiệp vụ chính thức trong kho mã nguồn còn ít, do đó nhiều phân tích phải suy luận từ mã nguồn. Điều này có thể khiến một số quy trình nghiệp vụ chưa được mô tả đầy đủ hoặc chưa phản ánh đúng ý định ban đầu của nhóm phát triển.

Độ bao phủ kiểm thử còn hạn chế. Trong khi hệ thống có nhiều nghiệp vụ quan trọng liên quan đến thanh toán, phân quyền và dữ liệu học tập, số lượng kiểm thử hiện tại chưa đủ để đảm bảo an toàn khi thay đổi mã nguồn.

Một số điểm trong mã nguồn cần xác minh thêm. Ví dụ, nghiệp vụ hóa đơn và giấy phép có dấu hiệu liên kết `Invoice` với `License`, nhưng cần kiểm tra lại lược đồ cơ sở dữ liệu để bảo đảm khóa ngoại tương ứng tồn tại. Ngoài ra, vai trò `employee` và cách truy vấn nhân viên trong một số phần doanh nghiệp cần được chuẩn hóa để tránh sai lệch báo cáo.

Quy trình chia doanh thu đã có dịch vụ xử lý nhưng cần xác minh chắc chắn dịch vụ này được gọi đầy đủ sau khi đăng ký học thành công. Nếu không, hệ thống có thể cấp quyền học nhưng không ghi nhận đúng doanh thu.

Một số dashboard tính toán trực tiếp trên dữ liệu hiện tại. Khi dữ liệu tăng lớn, cần tối ưu truy vấn hoặc tạo dữ liệu thống kê tổng hợp để tránh chậm.

### 11.3. Hướng phát triển tương lai

Hướng phát triển đầu tiên là hoàn thiện kiểm thử tự động cho các luồng nghiệp vụ quan trọng. Khi hệ thống xử lý thanh toán và phân quyền, kiểm thử không chỉ là yêu cầu kỹ thuật mà còn là yêu cầu bảo vệ dữ liệu và doanh thu.

Hướng phát triển thứ hai là chuẩn hóa mô hình doanh nghiệp, đặc biệt là vai trò nhân viên, quan hệ hóa đơn - giấy phép và báo cáo tiến độ. Điều này giúp module B2B trở nên ổn định và có thể sử dụng trong thực tế.

Hướng phát triển thứ ba là nâng cấp cá nhân hóa học tập. Hệ thống đã có dữ liệu hoạt động học tập, gợi ý khóa học và kế hoạch học. Có thể phát triển thêm phân tích điểm mạnh, điểm yếu, gợi ý bài học cần ôn tập, bài kiểm tra thích ứng và trợ lý học tập.

Hướng phát triển thứ tư là tối ưu hiệu năng cho dashboard, recommendation và truy vấn danh sách khóa học khi số lượng dữ liệu lớn. Có thể sử dụng bộ nhớ đệm, bảng thống kê hoặc công việc nền định kỳ.

Hướng phát triển thứ năm là hoàn thiện trải nghiệm sau khi hoàn thành khóa học, bao gồm chứng chỉ có thể xác thực công khai, xuất tệp PDF, chia sẻ lên hồ sơ nghề nghiệp và thống kê thành tích học tập.

## 12. Gợi Ý Bố Cục Báo Cáo Chính Thức

Báo cáo có thể được xây dựng theo bảy chương. Chương một giới thiệu đề tài, lý do chọn đề tài, mục tiêu và phạm vi. Chương hai trình bày cơ sở lý thuyết như hệ thống E-Learning, kiến trúc MVC, quy trình phát triển phần mềm, xác thực, phân quyền và thanh toán trực tuyến.

Chương ba phân tích yêu cầu, bao gồm tác nhân, yêu cầu chức năng, yêu cầu phi chức năng và các ca sử dụng chính. Chương bốn thiết kế hệ thống, gồm kiến trúc tổng thể, mô hình dữ liệu, phân quyền, luồng xử lý và thiết kế module. Chương năm trình bày cài đặt hệ thống ở mức tổng quan, mô tả các module đã phát triển và các quyết định thiết kế quan trọng.

Chương sáu trình bày kiểm thử, gồm chiến lược kiểm thử, các trường hợp kiểm thử tiêu biểu và nhận xét kết quả. Chương bảy đánh giá hệ thống, nêu ưu điểm, hạn chế và hướng phát triển tương lai.

## 13. Ghi Chú Thiết Kế Và Mẫu Thiết Kế

Hệ thống sử dụng kiến trúc MVC để tách dữ liệu, xử lý và giao diện. Đây là mẫu kiến trúc phù hợp với ứng dụng web có nhiều màn hình và nhiều thực thể dữ liệu.

Hệ thống có áp dụng lớp dịch vụ (Service Object) cho các nghiệp vụ phức tạp. Vai trò của mẫu này là đóng gói logic nghiệp vụ như mua giấy phép, chia doanh thu, lập kế hoạch học và tính gợi ý, tránh để bộ điều khiển trở nên quá lớn.

Hệ thống có sử dụng công việc nền (Background Job) cho các tác vụ không cần phản hồi ngay lập tức. Đây là quyết định thiết kế quan trọng để cải thiện trải nghiệm người dùng và khả năng mở rộng.

Hệ thống sử dụng mô hình phân quyền tập trung thông qua lớp Ability. Cách thiết kế này giúp các quy tắc quyền truy cập được quản lý nhất quán thay vì rải rác trong nhiều bộ điều khiển.

## 14. Kết Luận Phân Tích

Qua phân tích mã nguồn, có thể nhận định đây là một hệ thống E-Learning có phạm vi tương đối lớn, kết hợp giữa quản lý học tập, thương mại điện tử, quản trị nội dung, phân tích học tập và đào tạo doanh nghiệp. Dự án phù hợp để viết báo cáo môn Công nghệ Phần mềm vì có đầy đủ các khía cạnh cần phân tích: yêu cầu nghiệp vụ, ca sử dụng, thiết kế dữ liệu, kiến trúc hệ thống, phân quyền, quy trình xử lý, kiểm thử và triển khai.

Giá trị nổi bật của hệ thống nằm ở việc mô hình hóa đầy đủ nhiều bên tham gia trong nền tảng học trực tuyến. Học viên nhận được trải nghiệm học tập có theo dõi tiến độ và cá nhân hóa. Giảng viên có công cụ tạo nội dung và tạo doanh thu. Quản trị viên kiểm soát chất lượng và vận hành. Doanh nghiệp có cơ chế đào tạo nhân viên tập trung. Đây là cơ sở tốt để phát triển thành một báo cáo đồ án có chiều sâu cả về nghiệp vụ lẫn thiết kế phần mềm.
