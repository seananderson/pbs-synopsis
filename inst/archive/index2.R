d <- readRDS("../../Dropbox/dfo/data/all-survey-catches.rds")
names(d) <- tolower(names(d))
d$species_common_name <- tolower(d$species_common_name)
d$species_science_name <- tolower(d$species_science_name)

library(tidyverse)
library(mapdata)
library(lubridate)
mpc <- ggplot2::map_data("world", "Canada") # low res

d$year <- lubridate::year(d$trip_start_date)

sp <- filter(d, species_common_name %in% "pacific ocean perch") %>% 
  filter(!is.na(catch_weight)) %>% 
  filter(year %in% seq(2004, 2012, 2))

dat <- sp
dat <- filter(dat, start_lon > -128, start_lon < 125, start_lat > 48, start_lat < 50.3)
nrow(dat)
dat <- filter(dat, fe_bottom_water_temperature > 1, fe_bottom_water_temperature < 12,
  !is.na(fe_bottom_water_temp_depth), !is.na(fe_bottom_water_temperature))
nrow(dat)

# dat <- mutate(dat, density = catch_weight / 
    # (fe_distance_travelled * mean(d$trlsp_doorspread, na.rm = TRUE)))

## depth map:
library(sp)
# library(gstat)
library(marmap)
mm <- getNOAA.bathy(lon1 = -128,lon2 = -125,lat1=48,lat2=50, resolution=1) 
plot(mm, image=TRUE)
plot(as.raster(mm))
bath <- as.xyz(mm) %>% rename(start_lon = V1, start_lat = V2, depth = V3) %>% 
  filter(depth < 0) %>% mutate(depth = -depth) %>% 
  filter(!(start_lon > -126 & start_lat > 49.5)) # other side of island
ggplot(bath, aes(start_lon, start_lat)) + geom_tile(aes(fill = depth))

# library(mgcv)
# ctrl <- list(nthreads=4)
# m_bath <- bam(log(depth) ~ te(start_lon, start_lat, k = 20), data = bath,
#   control = ctrl)
# plot(m_bath)
# bath$pred <- predict(m_bath)
# ggplot(bath, aes(start_lon, start_lat)) +
#   coord_equal(
#     xlim = c(-128, -125.5),
#     ylim = c(48, 50.3)) +
#   geom_point(aes(color = exp(pred) - depth)) +
#   scale_colour_gradient2(limits = c(-1000, 1000)) +
#   geom_polygon(data = mpc, aes(x = long, y = lat, group = group), fill = "grey50")
# ##

# # krigging option:
# coordinates(bath) <- ~ start_lon + start_lat
# lzn.vgm <- variogram(log(depth)~1, bath)
# plot(lzn.vgm)
# lzn.fit <- fit.variogram(lzn.vgm, model=vgm(model = "Gau")) # fit model
# plot(lzn.vgm, lzn.fit)
# lzn.kriged <- krige(log(depth) ~ 1, bath, bath, model=lzn.fit)
# as.data.frame(lzn.kriged)
# ##

# bilinear interp.

library(akima)
# dat$depth_akima <- plyr::alply(dat, 1, function(x) {
#   interp(x = bath$start_lon, 
#     y = bath$start_lat,
#     z = bath$depth,
#     xo = x$start_lon[[1]],
#     yo = x$start_lat[[1]])$z
# }) %>% unlist()

ii <- interp(x = bath$start_lon, 
  y = bath$start_lat,
  z = log(bath$depth),
  xo = sort(unique(dat$start_lon)),
  yo = sort(unique(dat$start_lat)))

z = reshape2::melt(ii$z)
z$x <- ii$x[z$Var1]
z$y <- ii$y[z$Var2]
z <- filter(z, paste(x, y) %in% paste(dat$start_lon, dat$start_lat))
z$value <- exp(z$value)
ggplot(z, aes(x, y, 
  color = value)) +
  geom_point() +
  viridis::scale_colour_viridis()
z <- rename(z, start_lon = x, start_lat = y, akima_depth = value) %>% 
  select(-Var1, -Var2)

dat <- left_join(dat, z)

plot(dat$akima_depth, dat$fe_bottom_water_temp_depth)

ggplot(dat, aes(start_lon, start_lat, 
  color = depth_akima - fe_bottom_water_temp_depth)) +
  geom_point() +
  scale_colour_gradient2()

g <- ggplot(dat, aes(start_lon, start_lat)) +
  coord_equal(
    xlim = c(-128, -125),
    ylim = c(48, 50.3)) +
  stat_summary_hex(aes(z = catch_weight),
    binwidth = 0.05, fun = function(x) mean(log(x))) +
  viridis::scale_fill_viridis() +
  facet_wrap(~year) +
  geom_polygon(data = mpc, aes(x = long, y = lat, group = group), fill = "grey50")
g

g <- ggplot(dat, aes(start_lon, start_lat)) +
  coord_equal(
    xlim = c(-128, -125),
    ylim = c(48, 50.3)) +
  stat_summary_hex(aes(z = fe_bottom_water_temperature),
    binwidth = 0.05, fun = function(x) mean((x))) +
  viridis::scale_fill_viridis() +
  facet_wrap(~year) +
  geom_polygon(data = mpc, aes(x = long, y = lat, group = group), fill = "grey50")
g

g <- ggplot(dat, aes(start_lon, start_lat)) +
  coord_equal(
    xlim = c(-128, -125),
    ylim = c(48, 50.3)) +
  stat_summary_hex(aes(z = akima_depth),
    binwidth = 0.05, fun = function(x) mean((x))) +
  viridis::scale_fill_viridis() +
  facet_wrap(~year) +
  geom_polygon(data = mpc, aes(x = long, y = lat, group = group), fill = "grey50")
g

# create perchiness index:
load("survey_dat.rda")
library(mgcv)
d_loc_cpue_pop <- filter(d_loc_cpue_pop, 
  X > -128, X < 125, Y > 48, Y < 50.3)
ggplot(d_loc_cpue_pop, aes(X, Y, colour = log(cpue))) + geom_point()
mcpue <- gam(cpue ~ te(X, Y, k = 7), data = d_loc_cpue_pop, family = Gamma(link = "log"))
plot(mcpue)
dat$X <- dat$start_lon
dat$Y <- dat$start_lat
dat$cpue_gam <- predict(mcpue, newdata = dat)

ggplot(dat, aes(X, Y, colour = log(cpue_gam))) + geom_point()

dat$depth_scaled <- as.numeric(scale(log(dat$akima_depth)))
dat$temp_scaled <- as.numeric(scale(dat$fe_bottom_water_temperature))
dat$depth_scaled2 <- dat$depth_scaled^2
dat$temp_scaled2 <- dat$temp_scaled^2
dat$cpue_gam_scaled <- as.numeric(scale(dat$cpue_gam))
dat$cpue_gam_scaled2 <- dat$cpue_gam_scaled^2

m_depth_scaled <- gam(depth_scaled ~ te(start_lon, start_lat, k = 10), 
  data = dat)
plot(m_depth_scaled)

m_temp_scaled <- gam(temp_scaled ~ te(start_lon, start_lat, k = 10), 
  data = dat)
plot(m_temp_scaled)

initf <- function(n_time, n_knots, n_beta) {
  list(
    phi      = array(runif(1, 0.4, 0.7), dim = 1), 
    gp_sigma = rlnorm(1, log(0.8), 0.05), 
    gp_theta = rlnorm(1, log(0.1), 0.05), 
    B        = c(mean(log(dat$catch_weight)), rnorm(n_beta, 0, 0.05)),
    sigma    = array(rlnorm(1, log(1.0), 0.05), dim = 1),
    spatialEffectsKnots = 
      matrix(runif(n_time * n_knots, -0.05, 0.05), nrow = n_time, ncol = n_knots))
}

load_all("../glmmfields/")

n_knots <- 30L
n_beta <- 6L

m <- glmmfields(log(catch_weight) ~ as.factor(year) + 
    depth_scaled + depth_scaled2 #+
  # temp_scaled + temp_scaled2
  # + cpue_gam_scaled
  ,
  time = "year",
  lon = "start_lon", lat = "start_lat",
  data = dat, iter = 600,
  prior_gp_theta = half_t(100, 0, 2),
  prior_gp_sigma = half_t(100, 0, 2),
  prior_intercept = half_t(100, 0, 5),
  prior_beta = half_t(100, 0, 2),
  nknots = n_knots, cluster = "pam", chains = 3, cores = 3,
  seed = 1,
  thin = 1, covariance = "squared-exponential",
  init = function() {initf(length(unique(dat$year)), n_knots, n_beta)},
  estimate_ar = TRUE, estimate_df = FALSE, year_re = FALSE,
  control = list(adapt_delta = 0.99, max_treedepth = 20))
m
plot(m) + viridis::scale_color_viridis()
plot(m, type = "residual-vs-fitted")
plot(m, type = "spatial-residual")

plot(m$model, pars = paste0("B[", 6:10, "]"))

## prediction
x <- dat$start_lon
y <- dat$start_lat
z <- chull(x,y)
coords <- cbind(x[z], y[z])
coords <- rbind(coords, coords[1,])
plot(dat$start_lon, dat$start_lat)
lines(coords, col="red")

library("rgdal")
sp_poly <- SpatialPolygons(list(Polygons(list(Polygon(coords)), ID=1)))
# set coordinate reference system with SpatialPolygons(..., proj4string=CRS(...))
# e.g. CRS("+proj=longlat +datum=WGS84")
sp_poly_df <- SpatialPolygonsDataFrame(sp_poly, data=data.frame(ID=1))

pred_grid <- expand.grid(start_lon = seq(-129, -124, 0.02), 
  start_lat = seq(46, 51, 0.02), year = unique(dat$year))
coordinates(pred_grid) <- c("start_lon", "start_lat")
inside <- !is.na(over(pred_grid, as(sp_poly_df, "SpatialPolygons")))
pred_grid <- pred_grid[inside, ]
# plot(pred_grid)

pred_grid <- as.data.frame(pred_grid)
# pred_grid$depth_scaled <- predict(m_depth_scaled, newdata = pred_grid)

ii <- interp(x = bath$start_lon, 
  y = bath$start_lat,
  z = log(bath$depth),
  xo = sort(unique(pred_grid$start_lon)),
  yo = sort(unique(pred_grid$start_lat)))

z = reshape2::melt(ii$z)
z$x <- ii$x[z$Var1]
z$y <- ii$y[z$Var2]
z <- filter(z, paste(x, y) %in% paste(pred_grid$start_lon, pred_grid$start_lat))
z$value <- exp(z$value)
ggplot(z, aes(x, y, 
  fill = value)) +
  geom_raster() +
  viridis::scale_fill_viridis()
z <- rename(z, start_lon = x, start_lat = y, akima_depth = value) %>% 
  select(-Var1, -Var2)

pred_grid <- left_join(as.data.frame(pred_grid), z)

pred_grid$depth_scaled <- (log(pred_grid$akima_depth) - 
    mean(log(dat$akima_depth))) / sd(log(dat$akima_depth))
pred_grid$temp_scaled <- predict(m_temp_scaled, newdata = pred_grid)

cpue_pred <- predict(mcpue, 
  newdata = dplyr::mutate(pred_grid, X = start_lon, Y = start_lat))
pred_grid$cpue_gam_scaled <- (cpue_pred - mean(dat$cpue_gam)) / sd(dat$cpue_gam)

pred_grid$depth_scaled2 <- pred_grid$depth_scaled^2
pred_grid$temp_scaled2 <- pred_grid$temp_scaled^2

# pred_grid <- mutate(as.data.frame(pred_grid), 
#   cpue_gam_scaled = 0, depth_scaled = 0, depth_scaled2 = 0,
#   temp_scaled = 0, temp_scaled2 = 0)
pred_grid$p <- predict(m, newdata = pred_grid)$estimate

mpc <- ggplot2::map_data("worldHires", "Canada") # high res
g <- ggplot(pred_grid, aes(start_lon, start_lat)) +
  coord_equal(
    xlim = c(-128, -125),
    ylim = c(48, 50.3)) +
  geom_raster(aes(fill = sqrt(exp(p)))) +
  viridis::scale_fill_viridis() +
  facet_wrap(~year) +
  theme_light() +
  guides(fill = FALSE) +
  geom_polygon(data = mpc, aes(x = long, y = lat, group = group), fill = "grey50") +
  geom_point(data = dat, col = "white", pch = 4, alpha = 0.5)
g
ggsave("spatial-ind-map-pop-sqrt.pdf", width = 16, height = 8)

# group_by(pred_grid, year) %>% summarise(b = sum(exp(p)))

pp <- predict(m, newdata = pred_grid, return_mcmc = TRUE)

ind <- plyr::llply(seq(2004, 2012, 2), function(y_) {
  apply(pp[which(pred_grid$year == y_), ], 2, function(x_) sum(exp(x_)))
})
ind <- reshape2::melt(t(plyr::ldply(ind)))
sum_ind <- group_by(ind, Var2) %>% 
  summarise(m = median(value),
    l = quantile(value, probs = 0.025),
    u = quantile(value, probs = 0.975)
  )
ggplot(ind, aes(as.factor(Var2), value/20)) + 
  geom_violin(col = "grey70", fill = "grey70") +
  geom_pointrange(data = sum_ind, aes(y = m/20, ymin = l/20, ymax = u/20)) +
  theme_light() +
  ylim(0, max(ind$value)/20)
ggsave("spatial-ind-est-pop.pdf", width = 7, height = 4)
