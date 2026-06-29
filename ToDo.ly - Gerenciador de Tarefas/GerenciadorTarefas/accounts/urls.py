<<<<<<< HEAD
from django.urls import path, include
from . import views
urlpatterns = [
    path('register/', views.SignUp.as_view(), name='signup'),
]
=======
from django.urls import path, include
from . import views
urlpatterns = [
    path('register/', views.SignUp.as_view(), name='signup'),
]
>>>>>>> e3538acd12e77e740b8ff1fd993c39a8ba873cd9
