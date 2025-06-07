use actix_web::web;
use crate::controllers::api_base::get_csrf_token;
use crate::controllers::health_controller::{health_check, health_details};

// Import BOTH controller functions
use crate::controllers::auth_signup_controller::{register_user_controller, register_owner_controller};
use crate::controllers::auth_signin_controller::{
    signin, signout, refresh_token, get_current_user,
    request_password_reset, verify_password_reset, complete_password_reset
};
use crate::controllers::parking_search_controller::{
    search_parking_lots_controller,
    get_favorite_parking_lots_controller,
    manage_favorite_parking_lot_controller,
    get_parking_lot_detail_controller,
};

pub fn init_routes(cfg: &mut web::ServiceConfig) {
    // Health check endpoints
    cfg.service(health_check);
    cfg.service(health_details);

    // Auth routes with common prefix
    cfg.service(
        web::scope("/v1/api/auth")
            .service(signin)
            .service(signout)
            .service(refresh_token)
            .service(get_current_user)
            .service(get_csrf_token)
            .service(
                web::scope("/password-reset")
                    .service(request_password_reset)
                    .service(verify_password_reset)
                    .service(complete_password_reset)
            )
            .service(
                web::scope("/signup")
                    .service(register_user_controller)
                    .service(register_owner_controller)
            )
    );

    // Parking search routes
    cfg.service(
        web::scope("/v1/api/parking")
            .service(search_parking_lots_controller)
            .service(get_favorite_parking_lots_controller)
            .service(manage_favorite_parking_lot_controller)
            .service(get_parking_lot_detail_controller)
    );

    // 示例：带参数的 resource 路由
    cfg.route("/api/v1/resource/{id}/{name}/index.html", web::get().to(|path: web::Path<(u32, String)>| async move {
        let (id, name) = path.into_inner();
        format!("Resource: id={}, name={}", id, name)
    }));
    // 你可以根据需要添加更多 route/resource
}