import 'package:flutter/material.dart';

class DashboardHeader extends StatelessWidget implements PreferredSizeWidget {
  final String userName;
  final String currentDate;
  final String headquartersName;
  final String headquartersZone;
  final VoidCallback? onProfileTap;

  const DashboardHeader({
    super.key,
    required this.userName,
    required this.currentDate,
    required this.headquartersName,
    required this.headquartersZone,
    this.onProfileTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, $userName',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentDate,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Icon(
                  Icons.house_outlined,
                  color: Colors.grey.shade600,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headquartersName,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      headquartersZone,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            GestureDetector(
              onTap: onProfileTap,
              child: Icon(
                Icons.person_outline,
                color: Colors.grey.shade600,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
