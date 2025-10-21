# HR Recruitment Backend

This backend mirrors the structure of khoii1/Ecom_backend (src/, .env.example, .gitignore, package.json) and implements an HR recruitment system with:
- Thiết lập quy trình tuyển dụng (processes + stages)
- Đăng thông tin tuyển dụng (jobs)
- Nhận hồ sơ ứng viên (applications)
- Sàng lọc đánh giá và gửi kết quả (evaluations + email)
- Đặt lịch phỏng vấn (interviews)
- Lập hội đồng tổ chức tuyển dụng (committees + members)
- Quản lý và lưu trữ kết quả tuyển dụng (results)
- Tạo thư mời nhận việc (offers + email)
- Báo cáo thống kê (reports)

## Cấu trúc
- `src/` mã nguồn Express
- `db/schema.sql` schema PostgreSQL
- `.env.example` biến môi trường mẫu
- `HR_API_Collection.postman_collection.json` Postman collection

## Thiết lập (Windows PowerShell)
1. Tạo file `.env` từ `.env.example` và cập nhật `DATABASE_URL` (PostgreSQL), `JWT_SECRET`, `SENDGRID_API_KEY` (nếu dùng email).
2. Cài dependencies và chạy dev:

```powershell
# Tại thư mục HR
npm init -y; npm pkg set type=module; npm install express dotenv pg express-validator jsonwebtoken bcryptjs slugify @sendgrid/mail; npm i -D nodemon
# Ghi đè scripts nếu cần
npm pkg set scripts.dev="node --watch src/server.js"; npm pkg set scripts.start="node src/server.js"
```

3. Tạo database và chạy schema:
```powershell
# Sử dụng psql hoặc GUI (pgAdmin). Với psql ví dụ:
# psql -d hr_recruitment -f db/schema.sql
```

4. Chạy server:
```powershell
npm run dev
```

5. Kiểm tra:
- GET http://localhost:4000/health
- Dùng Postman import `HR_API_Collection.postman_collection.json`

## Ghi chú
- Ứng dụng khởi động được dù chưa có DB, nhưng các endpoint truy vấn DB sẽ lỗi nếu `DATABASE_URL` không cấu hình.
- Email sẽ bỏ qua nếu không có `SENDGRID_API_KEY`.

## Tiếp theo (gợi ý)
- Thêm xác thực người dùng, phân quyền theo vai trò.
- Viết tests (Jest/Supertest).
- Thêm migration tool (Prisma/Knex) thay cho SQL tay.
